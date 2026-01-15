<#
.SYNOPSIS
    Initialize all SQLite databases.

.DESCRIPTION
    Creates and initializes all SQLite databases used by the profile.
    This script can be run independently to set up databases before first use.

.EXAMPLE
    .\initialize-databases.ps1
    Initializes all databases.
#>

[CmdletBinding()]
param()

# Import required modules
$moduleImportPath = Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'lib' 'ModuleImport.psm1'
Import-Module $moduleImportPath -DisableNameChecking -ErrorAction Stop

# Parse debug level once at script start
$debugLevel = 0
if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel)) {
    # Debug is enabled, $debugLevel contains the numeric level (1-3)
}

Import-LibModule -ModuleName 'ExitCodes' -ScriptPath $PSScriptRoot -DisableNameChecking
Import-LibModule -ModuleName 'Logging' -ScriptPath $PSScriptRoot -DisableNameChecking

# Import SQLite utilities
$sqliteModule = Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'lib' 'utilities' 'SqliteDatabase.psm1'
Import-Module $sqliteModule -DisableNameChecking -ErrorAction Stop

# Import database modules
$databaseModulesPath = Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'lib' 'database'
$commandHistoryModule = Join-Path $databaseModulesPath 'CommandHistoryDatabase.psm1'
$performanceMetricsModule = Join-Path $databaseModulesPath 'PerformanceMetricsDatabase.psm1'
$testCacheModule = Join-Path $databaseModulesPath 'TestCacheDatabase.psm1'

Import-Module $commandHistoryModule -DisableNameChecking -ErrorAction SilentlyContinue
Import-Module $performanceMetricsModule -DisableNameChecking -ErrorAction SilentlyContinue
Import-Module $testCacheModule -DisableNameChecking -ErrorAction SilentlyContinue

# Level 1: Basic operation start
if ($debugLevel -ge 1) {
    Write-Verbose "[database.initialize] Starting database initialization"
}

Write-Host "`nInitializing SQLite Databases" -ForegroundColor Cyan
Write-Host "=============================" -ForegroundColor Cyan
Write-Host ""

# Check SQLite availability
if (-not (Test-SqliteAvailable)) {
    Write-Host "✗ SQLite is not available" -ForegroundColor Red
    Write-Host "  Install sqlite3: choco install sqlite -y (Windows) or brew install sqlite (macOS)" -ForegroundColor Yellow
    Exit-WithCode -ExitCode [ExitCode]::SetupError
}

$sqliteCmd = Get-SqliteCommandName
Write-Host "SQLite available: $sqliteCmd" -ForegroundColor Green
Write-Host ""

$cacheDir = Get-CacheDirectory
Write-Host "Cache directory: $cacheDir" -ForegroundColor Gray
Write-Host ""

$successCount = 0
$failCount = 0

# Level 1: Command History Database initialization start
if ($debugLevel -ge 1) {
    Write-Verbose "[database.initialize] Initializing Command History Database"
}

# Initialize Command History Database
$initStartTime = Get-Date
Write-Host "Initializing Command History Database..." -ForegroundColor Yellow
try {
    if (Get-Command Initialize-CommandHistoryDb -ErrorAction SilentlyContinue) {
        $result = Initialize-CommandHistoryDb
        if ($result) {
            $dbPath = Get-CommandHistoryDbPath
            $initDuration = ((Get-Date) - $initStartTime).TotalMilliseconds
            
            # Level 2: Database initialization timing
            if ($debugLevel -ge 2) {
                Write-Verbose "[database.initialize] Command History Database initialized in ${initDuration}ms"
            }
            
            Write-Host "  ✓ Command History Database initialized" -ForegroundColor Green
            Write-Host "    Path: $dbPath" -ForegroundColor Gray
            $successCount++
        }
        else {
            Write-Host "  ✗ Command History Database initialization failed" -ForegroundColor Red
            $failCount++
        }
    }
    else {
        Write-Host "  ✗ Initialize-CommandHistoryDb function not found" -ForegroundColor Red
        $failCount++
    }
}
catch {
    Write-Host "  ✗ Error: $($_.Exception.Message)" -ForegroundColor Red
    $failCount++
}

Write-Host ""

# Level 1: Performance Metrics Database initialization start
if ($debugLevel -ge 1) {
    Write-Verbose "[database.initialize] Initializing Performance Metrics Database"
}

# Initialize Performance Metrics Database
Write-Host "Initializing Performance Metrics Database..." -ForegroundColor Yellow
$perfInitStartTime = Get-Date
try {
    if (Get-Command Initialize-PerformanceMetricsDb -ErrorAction SilentlyContinue) {
        $result = Initialize-PerformanceMetricsDb
        if ($result) {
            $dbPath = Get-PerformanceMetricsDbPath
            $perfInitDuration = ((Get-Date) - $perfInitStartTime).TotalMilliseconds
            
            # Level 2: Database initialization timing
            if ($debugLevel -ge 2) {
                Write-Verbose "[database.initialize] Performance Metrics Database initialized in ${perfInitDuration}ms"
            }
            
            Write-Host "  ✓ Performance Metrics Database initialized" -ForegroundColor Green
            Write-Host "    Path: $dbPath" -ForegroundColor Gray
            $successCount++
        }
        else {
            Write-Host "  ✗ Performance Metrics Database initialization failed" -ForegroundColor Red
            $failCount++
        }
    }
    else {
        Write-Host "  ✗ Initialize-PerformanceMetricsDb function not found" -ForegroundColor Red
        $failCount++
    }
}
catch {
    Write-Host "  ✗ Error: $($_.Exception.Message)" -ForegroundColor Red
    $failCount++
}

Write-Host ""

# Level 1: Test Cache Database initialization start
if ($debugLevel -ge 1) {
    Write-Verbose "[database.initialize] Initializing Test Cache Database"
}

# Initialize Test Cache Database
Write-Host "Initializing Test Cache Database..." -ForegroundColor Yellow
$testInitStartTime = Get-Date
try {
    if (Get-Command Initialize-TestCacheDb -ErrorAction SilentlyContinue) {
        $result = Initialize-TestCacheDb
        if ($result) {
            $dbPath = Get-TestCacheDbPath
            $testInitDuration = ((Get-Date) - $testInitStartTime).TotalMilliseconds
            
            # Level 2: Database initialization timing
            if ($debugLevel -ge 2) {
                Write-Verbose "[database.initialize] Test Cache Database initialized in ${testInitDuration}ms"
            }
            
            Write-Host "  ✓ Test Cache Database initialized" -ForegroundColor Green
            Write-Host "    Path: $dbPath" -ForegroundColor Gray
            $successCount++
        }
        else {
            Write-Host "  ✗ Test Cache Database initialization failed" -ForegroundColor Red
            $failCount++
        }
    }
    else {
        Write-Host "  ✗ Initialize-TestCacheDb function not found" -ForegroundColor Red
        $failCount++
    }
}
catch {
    Write-Host "  ✗ Error: $($_.Exception.Message)" -ForegroundColor Red
    $failCount++
}

$totalInitDuration = ((Get-Date) - $initStartTime).TotalMilliseconds

# Level 2: Overall initialization timing
if ($debugLevel -ge 2) {
    Write-Verbose "[database.initialize] Database initialization completed in ${totalInitDuration}ms"
    Write-Verbose "[database.initialize] Success: $successCount, Failed: $failCount"
}

# Level 3: Performance breakdown
if ($debugLevel -ge 3) {
    Write-Host "  [database.initialize] Performance - Total: ${totalInitDuration}ms, Success: $successCount, Failed: $failCount" -ForegroundColor DarkGray
}

Write-Host ""
Write-Host "Summary" -ForegroundColor Cyan
Write-Host "=======" -ForegroundColor Cyan
Write-Host "Success: $successCount" -ForegroundColor $(if ($successCount -eq 3) { 'Green' } else { 'Yellow' })
Write-Host "Failed:  $failCount" -ForegroundColor $(if ($failCount -eq 0) { 'Gray' } else { 'Red' })
Write-Host ""

if ($failCount -eq 0) {
    Write-Host "✓ All databases initialized successfully!" -ForegroundColor Green
    Exit-WithCode -ExitCode [ExitCode]::Success
}
else {
    Write-Host "✗ Some databases failed to initialize" -ForegroundColor Red
    Exit-WithCode -ExitCode [ExitCode]::SetupError
}
