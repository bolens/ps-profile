<#
.SYNOPSIS
    Verifies that the fragment cache was properly cleared.

.DESCRIPTION
    This script checks:
    - Database file exists and its size
    - Number of entries in each cache table
    - Whether cache clearing actually worked

.EXAMPLE
    pwsh -NoProfile -File scripts/utils/verify-cache-cleared.ps1
#>

[CmdletBinding()]
param()

Write-Host ""
Write-Host "=" * 70 -ForegroundColor Cyan
Write-Host "Fragment Cache Verification" -ForegroundColor Cyan
Write-Host "=" * 70 -ForegroundColor Cyan
Write-Host ""

# Import required modules
$repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$scriptsLibDir = Join-Path $repoRoot 'scripts' 'lib'
$fragmentLibDir = Join-Path $scriptsLibDir 'fragment'

# Import cache modules
$cachePathModule = Join-Path $fragmentLibDir 'FragmentCachePath.psm1'
$cacheSqliteModule = Join-Path $fragmentLibDir 'FragmentCacheSqlite.psm1'

if (-not (Test-Path -LiteralPath $cachePathModule)) {
    Write-Host "✗ FragmentCachePath module not found: $cachePathModule" -ForegroundColor Red
    exit 1
}

if (-not (Test-Path -LiteralPath $cacheSqliteModule)) {
    Write-Host "✗ FragmentCacheSqlite module not found: $cacheSqliteModule" -ForegroundColor Red
    exit 1
}

try {
    Import-Module $cachePathModule -DisableNameChecking -ErrorAction Stop -Force
    Import-Module $cacheSqliteModule -DisableNameChecking -ErrorAction Stop -Force
}
catch {
    Write-Host "✗ Failed to import modules: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Get database path
$dbPath = $null
if (Get-Command Get-FragmentCacheDbPath -ErrorAction SilentlyContinue) {
    try {
        $dbPath = Get-FragmentCacheDbPath
        Write-Host "[verify] Database path: $dbPath" -ForegroundColor Cyan
    }
    catch {
        Write-Host "✗ Failed to get database path: $($_.Exception.Message)" -ForegroundColor Red
        exit 1
    }
}
else {
    Write-Host "✗ Get-FragmentCacheDbPath not available" -ForegroundColor Red
    exit 1
}

# Check if database exists
if ($dbPath -and (Test-Path -LiteralPath $dbPath)) {
    $dbInfo = Get-Item -LiteralPath $dbPath
    Write-Host "✓ Database file exists" -ForegroundColor Green
    Write-Host "  Size: $($dbInfo.Length) bytes" -ForegroundColor DarkGray
    Write-Host "  Last modified: $($dbInfo.LastWriteTime)" -ForegroundColor DarkGray
    
    # Check SQLite availability
    if (-not (Get-Command Test-SqliteAvailable -ErrorAction SilentlyContinue)) {
        Write-Host "✗ Test-SqliteAvailable not available" -ForegroundColor Red
        exit 1
    }
    
    $sqliteAvailable = Test-SqliteAvailable
    if (-not $sqliteAvailable) {
        Write-Host "✗ SQLite not available - cannot query database" -ForegroundColor Red
        exit 1
    }
    
    $sqliteCmd = Get-SqliteCommandName
    if (-not $sqliteCmd) {
        Write-Host "✗ SQLite command not found" -ForegroundColor Red
        exit 1
    }
    
    Write-Host ""
    Write-Host "[verify] Querying database contents..." -ForegroundColor Cyan
    
    # Count AST cache entries
    $astCountQuery = "SELECT COUNT(*) FROM fragment_ast_cache;"
    $contentCountQuery = "SELECT COUNT(*) FROM fragment_content_cache;"
    
    $tempOut = [System.IO.Path]::GetTempFileName()
    $tempErr = [System.IO.Path]::GetTempFileName()
    $tempSql = [System.IO.Path]::GetTempFileName()
    
    try {
        $astCount = 0
        $contentCount = 0
        
        # Count AST entries - write query to temp file and pipe to sqlite3
        $astCountQuery | Out-File -FilePath $tempSql -Encoding UTF8 -NoNewline
        $astProcess = Start-Process -FilePath $sqliteCmd -ArgumentList $dbPath -NoNewWindow -Wait -PassThru -RedirectStandardInput $tempSql -RedirectStandardOutput $tempOut -RedirectStandardError $tempErr
        if ($astProcess.ExitCode -eq 0) {
            $astCountStr = (Get-Content -Path $tempOut -Raw -ErrorAction SilentlyContinue).Trim()
            if ([int]::TryParse($astCountStr, [ref]$astCount)) {
                Write-Host "  AST cache entries: $astCount" -ForegroundColor $(if ($astCount -eq 0) { 'Green' } else { 'Yellow' })
            }
            else {
                Write-Host "  AST cache entries: (could not parse: $astCountStr)" -ForegroundColor Yellow
            }
        }
        else {
            $errorOutput = Get-Content -Path $tempErr -Raw -ErrorAction SilentlyContinue
            Write-Host "  ✗ Failed to query AST cache: $errorOutput" -ForegroundColor Red
        }
        
        # Clear temp files
        Remove-Item -Path $tempOut -Force -ErrorAction SilentlyContinue
        Remove-Item -Path $tempErr -Force -ErrorAction SilentlyContinue
        Remove-Item -Path $tempSql -Force -ErrorAction SilentlyContinue
        
        # Count content entries
        $tempOut = [System.IO.Path]::GetTempFileName()
        $tempErr = [System.IO.Path]::GetTempFileName()
        $tempSql = [System.IO.Path]::GetTempFileName()
        
        $contentCountQuery | Out-File -FilePath $tempSql -Encoding UTF8 -NoNewline
        $contentProcess = Start-Process -FilePath $sqliteCmd -ArgumentList $dbPath -NoNewWindow -Wait -PassThru -RedirectStandardInput $tempSql -RedirectStandardOutput $tempOut -RedirectStandardError $tempErr
        if ($contentProcess.ExitCode -eq 0) {
            $contentCountStr = (Get-Content -Path $tempOut -Raw -ErrorAction SilentlyContinue).Trim()
            if ([int]::TryParse($contentCountStr, [ref]$contentCount)) {
                Write-Host "  Content cache entries: $contentCount" -ForegroundColor $(if ($contentCount -eq 0) { 'Green' } else { 'Yellow' })
            }
            else {
                Write-Host "  Content cache entries: (could not parse: $contentCountStr)" -ForegroundColor Yellow
            }
        }
        else {
            $errorOutput = Get-Content -Path $tempErr -Raw -ErrorAction SilentlyContinue
            Write-Host "  ✗ Failed to query content cache: $errorOutput" -ForegroundColor Red
        }
        
        # Summary
        Write-Host ""
        if ($astCount -eq 0 -and $contentCount -eq 0) {
            Write-Host "✓ Cache is cleared (both AST and content caches are empty)" -ForegroundColor Green
        }
        else {
            Write-Host "⚠ Cache is NOT fully cleared:" -ForegroundColor Yellow
            if ($astCount -gt 0) {
                Write-Host "  - AST cache has $astCount entries" -ForegroundColor Yellow
            }
            if ($contentCount -gt 0) {
                Write-Host "  - Content cache has $contentCount entries" -ForegroundColor Yellow
            }
            Write-Host ""
            Write-Host "  Run: task clear-fragment-cache" -ForegroundColor Cyan
        }
    }
    finally {
        Remove-Item -Path $tempOut -Force -ErrorAction SilentlyContinue
        Remove-Item -Path $tempErr -Force -ErrorAction SilentlyContinue
        Remove-Item -Path $tempSql -Force -ErrorAction SilentlyContinue
    }
}
else {
    Write-Host "✓ Database file does not exist (cache is cleared)" -ForegroundColor Green
}

Write-Host ""
exit 0
