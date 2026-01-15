<#
.SYNOPSIS
    Directly initialize SQLite databases without loading profile.
#>
param()

$ErrorActionPreference = 'Stop'

# Parse debug level once at script start
$debugLevel = 0
if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel)) {
    # Debug is enabled, $debugLevel contains the numeric level (1-3)
}

# Find SQLite
$sqlitePaths = @(
    'A:\Chocolatey\lib\SQLite\tools\sqlite3.exe'
    'C:\ProgramData\chocolatey\bin\sqlite3.exe'
    'sqlite3'
)

$sqliteCmd = $null
foreach ($path in $sqlitePaths) {
    if ($path -eq 'sqlite3') {
        $cmd = Get-Command $path -ErrorAction SilentlyContinue
        if ($cmd) {
            $sqliteCmd = $cmd.Source
            break
        }
    }
    elseif (Test-Path $path) {
        $sqliteCmd = $path
        break
    }
}

if (-not $sqliteCmd) {
    Write-Host "SQLite not found. Install with: choco install sqlite -y" -ForegroundColor Red
    exit 1
}

# Determine cache directory
$cacheDir = $null
if ($env:PS_PROFILE_CACHE_DIR) {
    $cacheDir = $env:PS_PROFILE_CACHE_DIR
    if (-not [System.IO.Path]::IsPathRooted($cacheDir)) {
        $repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
        $cacheDir = Join-Path $repoRoot $cacheDir
    }
}
elseif ($env:LOCALAPPDATA) {
    $cacheDir = Join-Path $env:LOCALAPPDATA 'PowerShellProfile'
}
elseif ($env:XDG_CACHE_HOME) {
    $cacheDir = Join-Path $env:XDG_CACHE_HOME 'powershell-profile'
}
elseif ($env:HOME) {
    $cacheDir = Join-Path $env:HOME '.cache' 'powershell-profile'
}
else {
    $cacheDir = Join-Path $env:TEMP 'PowerShellProfile'
}

if (-not (Test-Path $cacheDir)) {
    New-Item -ItemType Directory -Path $cacheDir -Force | Out-Null
}

Write-Host "Initializing SQLite Databases" -ForegroundColor Cyan
Write-Host "=============================" -ForegroundColor Cyan
Write-Host "SQLite: $sqliteCmd" -ForegroundColor Gray
Write-Host "Cache: $cacheDir" -ForegroundColor Gray
Write-Host ""

# Level 1: Basic operation start
if ($debugLevel -ge 1) {
    Write-Verbose "[database.init-direct] Starting database initialization"
    Write-Verbose "[database.init-direct] SQLite command: $sqliteCmd"
    Write-Verbose "[database.init-direct] Cache directory: $cacheDir"
}

$schemas = @{
    'command-history.db' = @"
CREATE TABLE IF NOT EXISTS command_history (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    command_line TEXT NOT NULL,
    execution_time REAL,
    exit_code INTEGER,
    start_time INTEGER NOT NULL,
    end_time INTEGER,
    session_id TEXT,
    working_directory TEXT,
    created_at INTEGER NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_command_history_start_time ON command_history(start_time);
CREATE INDEX IF NOT EXISTS idx_command_history_command ON command_history(command_line);
CREATE INDEX IF NOT EXISTS idx_command_history_session ON command_history(session_id);
PRAGMA journal_mode=WAL;
PRAGMA busy_timeout = 5000;
"@
    'performance-metrics.db' = @"
CREATE TABLE IF NOT EXISTS performance_metrics (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    metric_type TEXT NOT NULL,
    metric_name TEXT NOT NULL,
    value REAL NOT NULL,
    unit TEXT,
    test_suite TEXT,
    environment TEXT,
    timestamp INTEGER NOT NULL,
    metadata TEXT,
    created_at INTEGER NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_performance_metrics_timestamp ON performance_metrics(timestamp);
CREATE INDEX IF NOT EXISTS idx_performance_metrics_type ON performance_metrics(metric_type, metric_name);
CREATE INDEX IF NOT EXISTS idx_performance_metrics_test_suite ON performance_metrics(test_suite);
PRAGMA journal_mode=WAL;
PRAGMA busy_timeout = 5000;
"@
    'test-cache.db' = @"
CREATE TABLE IF NOT EXISTS test_cache (
    test_file_path TEXT PRIMARY KEY,
    file_hash TEXT NOT NULL,
    last_write_time_ticks INTEGER NOT NULL,
    test_result TEXT NOT NULL,
    execution_time REAL,
    passed_count INTEGER,
    failed_count INTEGER,
    skipped_count INTEGER,
    cached_at INTEGER NOT NULL,
    updated_at INTEGER NOT NULL
);
CREATE TABLE IF NOT EXISTS test_execution_history (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    test_file_path TEXT NOT NULL,
    execution_time REAL,
    passed_count INTEGER,
    failed_count INTEGER,
    skipped_count INTEGER,
    timestamp INTEGER NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_test_cache_updated ON test_cache(updated_at);
CREATE INDEX IF NOT EXISTS idx_test_execution_history_timestamp ON test_execution_history(timestamp);
CREATE INDEX IF NOT EXISTS idx_test_execution_history_file ON test_execution_history(test_file_path);
PRAGMA journal_mode=WAL;
PRAGMA busy_timeout = 5000;
"@
}

$successCount = 0
$failCount = 0

# Level 2: Database list
if ($debugLevel -ge 2) {
    Write-Verbose "[database.init-direct] Initializing $($schemas.Keys.Count) databases: $($schemas.Keys -join ', ')"
}

foreach ($dbName in $schemas.Keys) {
    $dbPath = Join-Path $cacheDir $dbName
    
    # Level 1: Individual database start
    if ($debugLevel -ge 1) {
        Write-Verbose "[database.init-direct] Initializing database: $dbName"
    }
    
    Write-Host "Creating $dbName..." -NoNewline -ForegroundColor Yellow
    
    $dbStartTime = Get-Date
    try {
        $schemas[$dbName] | & $sqliteCmd $dbPath 2>&1 | Out-Null
        $dbDuration = ((Get-Date) - $dbStartTime).TotalMilliseconds
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host " ✓" -ForegroundColor Green
            $successCount++
            
            # Level 2: Timing information
            if ($debugLevel -ge 2) {
                Write-Verbose "[database.init-direct] Database $dbName initialized in ${dbDuration}ms"
            }
        }
        else {
            Write-Host " ✗ (exit code: $LASTEXITCODE)" -ForegroundColor Red
            $failCount++
            
            # Level 2: Error details
            if ($debugLevel -ge 2) {
                Write-Verbose "[database.init-direct] Database $dbName failed with exit code: $LASTEXITCODE"
            }
        }
    }
    catch {
        if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
            Write-StructuredError -ErrorRecord $_ -OperationName 'database.init-direct' -Context @{
                database_name = $dbName
                database_path = $dbPath
            }
        }
        else {
            Write-Host " ✗ ($($_.Exception.Message))" -ForegroundColor Red
        }
        $failCount++
    }
}

Write-Host ""

# Level 1: Summary
if ($debugLevel -ge 1) {
    Write-Verbose "[database.init-direct] Initialization complete - Success: $successCount, Failed: $failCount"
}

# Level 3: Performance breakdown
if ($debugLevel -ge 3) {
    $totalDbs = $successCount + $failCount
    $successRate = if ($totalDbs -gt 0) { [math]::Round(($successCount / $totalDbs) * 100, 2) } else { 0 }
    Write-Host "  [database.init-direct] Performance - Success rate: ${successRate}%, Total: $totalDbs databases" -ForegroundColor DarkGray
}

if ($failCount -eq 0) {
    Write-Host "All databases initialized successfully!" -ForegroundColor Green
    Get-ChildItem "$cacheDir\*.db" | Select-Object Name, @{N='Size (KB)';E={[math]::Round($_.Length/1KB,2)}}, LastWriteTime | Format-Table -AutoSize
    exit 0
}
else {
    Write-Host "Some databases failed to initialize" -ForegroundColor Red
    exit 1
}
