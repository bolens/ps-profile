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


# Import ExitCodes for standardized exit handling
$_ewcScriptsDir = Split-Path -Parent $PSScriptRoot
$_ewcLibPath = Join-Path $_ewcScriptsDir 'lib' 'ModuleImport.psm1'
if (-not (Test-Path $_ewcLibPath)) {
    $_ewcScriptsDir = Split-Path -Parent $_ewcScriptsDir
    $_ewcLibPath = Join-Path $_ewcScriptsDir 'lib' 'ModuleImport.psm1'
}
if (Test-Path $_ewcLibPath) {
    Import-Module $_ewcLibPath -DisableNameChecking -ErrorAction Stop
    Import-LibModule -ModuleName 'ExitCodes' -ScriptPath $PSScriptRoot -DisableNameChecking -Global
} else {
    function script:Exit-WithCode { param([object]$ExitCode, [string]$Message) if ($Message) { Write-Host $Message }; exit [int]$ExitCode }
    enum ExitCode { Success = 0; ValidationFailure = 1; SetupError = 2; OtherError = 3 }
}
Write-Host ""
Write-Host "=" * 70 -ForegroundColor Cyan
Write-Host "Fragment Cache Verification" -ForegroundColor Cyan
Write-Host "=" * 70 -ForegroundColor Cyan
Write-Host ""

# Import required modules
$repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$scriptsLibDir = Join-Path $repoRoot 'scripts' 'lib'
$fragmentLibDir = Join-Path $scriptsLibDir 'fragment'

# Import cache path module (FragmentCacheSqlite was removed; sqlite3 CLI is used when needed)
$cachePathModule = Join-Path $fragmentLibDir 'FragmentCachePath.psm1'

if (-not (Test-Path -LiteralPath $cachePathModule)) {
    Write-Host "✗ FragmentCachePath module not found: $cachePathModule" -ForegroundColor Red
    Exit-WithCode -ExitCode $EXIT_VALIDATION_FAILURE
}

try {
    Import-Module $cachePathModule -DisableNameChecking -ErrorAction Stop -Force
}
catch {
    Write-Host "✗ Failed to import FragmentCachePath: $($_.Exception.Message)" -ForegroundColor Red
    Exit-WithCode -ExitCode $EXIT_VALIDATION_FAILURE
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
        Exit-WithCode -ExitCode $EXIT_VALIDATION_FAILURE
    }
}
else {
    Write-Host "✗ Get-FragmentCacheDbPath not available" -ForegroundColor Red
    Exit-WithCode -ExitCode $EXIT_VALIDATION_FAILURE
}

# Check if database exists
if ($dbPath -and (Test-Path -LiteralPath $dbPath)) {
    $dbInfo = Get-Item -LiteralPath $dbPath
    Write-Host "✓ Database file exists" -ForegroundColor Green
    Write-Host "  Size: $($dbInfo.Length) bytes" -ForegroundColor DarkGray
    Write-Host "  Last modified: $($dbInfo.LastWriteTime)" -ForegroundColor DarkGray
    
    $sqliteCmd = $null
    if (Get-Command sqlite3 -ErrorAction SilentlyContinue) {
        $sqliteCmd = (Get-Command sqlite3).Source
    }
    if (-not $sqliteCmd) {
        Write-Host "⚠ SQLite not available - cannot query database entry counts" -ForegroundColor Yellow
        Write-Host "  Database file exists; run clear-fragment-cache if you expected an empty cache." -ForegroundColor Yellow
        if ($env:PS_PROFILE_CACHE_DIR -and $env:PS_PROFILE_TEST_MODE -eq '1') {
            return
        }
        Exit-WithCode -ExitCode $EXIT_SUCCESS
    }
    
    Write-Host ""
    Write-Host "[verify] Querying database contents..." -ForegroundColor Cyan
    
    # Count AST cache entries
    $astCountQuery = "SELECT COUNT(*) FROM fragment_ast_cache;"
    $contentCountQuery = "SELECT COUNT(*) FROM fragment_content_cache;"
    
    $astCount = 0
    $contentCount = 0

    $astOutput = @(& $sqliteCmd $dbPath $astCountQuery 2>&1)
    if ($LASTEXITCODE -eq 0) {
        $astCountStr = ($astOutput -join [Environment]::NewLine).Trim()
        if ([int]::TryParse($astCountStr, [ref]$astCount)) {
            Write-Host "  AST cache entries: $astCount" -ForegroundColor $(if ($astCount -eq 0) { 'Green' } else { 'Yellow' })
        }
        else {
            Write-Host "  AST cache entries: (could not parse: $astCountStr)" -ForegroundColor Yellow
        }
    }
    else {
        Write-Host "  ✗ Failed to query AST cache: $($astOutput -join [Environment]::NewLine)" -ForegroundColor Red
    }

    $contentOutput = @(& $sqliteCmd $dbPath $contentCountQuery 2>&1)
    if ($LASTEXITCODE -eq 0) {
        $contentCountStr = ($contentOutput -join [Environment]::NewLine).Trim()
        if ([int]::TryParse($contentCountStr, [ref]$contentCount)) {
            Write-Host "  Content cache entries: $contentCount" -ForegroundColor $(if ($contentCount -eq 0) { 'Green' } else { 'Yellow' })
        }
        else {
            Write-Host "  Content cache entries: (could not parse: $contentCountStr)" -ForegroundColor Yellow
        }
    }
    else {
        Write-Host "  ✗ Failed to query content cache: $($contentOutput -join [Environment]::NewLine)" -ForegroundColor Red
    }

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
else {
    Write-Host "✓ Database file does not exist (cache is cleared)" -ForegroundColor Green
}

Write-Host ""
if ($env:PS_PROFILE_CACHE_DIR -and $env:PS_PROFILE_TEST_MODE -eq '1') {
    return
}

Exit-WithCode -ExitCode $EXIT_SUCCESS
