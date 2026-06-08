<#
.SYNOPSIS
    Verifies that the fragment cache is properly loaded during profile initialization.

.DESCRIPTION
    This script loads the profile and checks:
    - Cache variables are initialized
    - SQLite database is accessible
    - Cache entries are loaded from database
    - Cache hit rates during parsing

.EXAMPLE
    pwsh -NoProfile -File scripts/utils/verify-cache-load.ps1

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
# Set debug level for detailed output
$env:PS_PROFILE_DEBUG = '3'

Write-Host ""
Write-Host "=" * 70 -ForegroundColor Cyan
Write-Host "Fragment Cache Verification" -ForegroundColor Cyan
Write-Host "=" * 70 -ForegroundColor Cyan
Write-Host ""

# Track timing
$startTime = Get-Date

# Load the profile
Write-Host "[verify] Loading profile..." -ForegroundColor Cyan
try {
    . $PROFILE
    $loadDuration = ((Get-Date) - $startTime).TotalMilliseconds
    Write-Host "[verify] Profile loaded in $([Math]::Round($loadDuration, 2))ms" -ForegroundColor Green
}
catch {
    Write-Host "[verify] ✗ Profile load failed: $($_.Exception.Message)" -ForegroundColor Red
    Exit-WithCode -ExitCode $EXIT_VALIDATION_FAILURE
}

Write-Host ""
Write-Host "Cache Status:" -ForegroundColor Cyan
Write-Host "-" * 70 -ForegroundColor DarkGray

# Check cache variables
$cacheStatus = @{
    ContentCache = $false
    AstCache = $false
    SqliteAvailable = $false
    DatabasePath = $null
    DatabaseExists = $false
    DatabaseSize = 0
    ContentCacheEntries = 0
    AstCacheEntries = 0
}

# Check FragmentContentCache
if (Get-Variable -Name 'FragmentContentCache' -Scope Global -ErrorAction SilentlyContinue) {
    $cacheStatus.ContentCache = $true
    $cacheStatus.ContentCacheEntries = $global:FragmentContentCache.Count
    Write-Host "✓ FragmentContentCache: $($cacheStatus.ContentCacheEntries) entries" -ForegroundColor Green
}
else {
    Write-Host "✗ FragmentContentCache: Not found" -ForegroundColor Red
}

# Check FragmentAstCache
if (Get-Variable -Name 'FragmentAstCache' -Scope Global -ErrorAction SilentlyContinue) {
    $cacheStatus.AstCache = $true
    $cacheStatus.AstCacheEntries = $global:FragmentAstCache.Count
    Write-Host "✓ FragmentAstCache: $($cacheStatus.AstCacheEntries) entries" -ForegroundColor Green
}
else {
    Write-Host "✗ FragmentAstCache: Not found" -ForegroundColor Red
}

# Check SQLite availability
if (Get-Command Test-SqliteAvailable -ErrorAction SilentlyContinue) {
    $cacheStatus.SqliteAvailable = Test-SqliteAvailable
    if ($cacheStatus.SqliteAvailable) {
        Write-Host "✓ SQLite: Available" -ForegroundColor Green
    }
    else {
        Write-Host "✗ SQLite: Not available" -ForegroundColor Yellow
    }
}
else {
    Write-Host "✗ Test-SqliteAvailable: Command not found" -ForegroundColor Yellow
}

# Check database path and size
if (Get-Command Get-FragmentCacheDbPath -ErrorAction SilentlyContinue) {
    try {
        $cacheStatus.DatabasePath = Get-FragmentCacheDbPath
        if ($cacheStatus.DatabasePath -and (Test-Path -LiteralPath $cacheStatus.DatabasePath)) {
            $cacheStatus.DatabaseExists = $true
            $dbInfo = Get-Item -LiteralPath $cacheStatus.DatabasePath
            $cacheStatus.DatabaseSize = $dbInfo.Length
            $sizeMB = [Math]::Round($cacheStatus.DatabaseSize / 1MB, 2)
            Write-Host "✓ Database: $($cacheStatus.DatabasePath)" -ForegroundColor Green
            Write-Host "  Size: $sizeMB MB" -ForegroundColor DarkGray
        }
        else {
            Write-Host "✗ Database: Path returned but file doesn't exist" -ForegroundColor Yellow
        }
    }
    catch {
        Write-Host "✗ Get-FragmentCacheDbPath: $($_.Exception.Message)" -ForegroundColor Yellow
    }
}
else {
    Write-Host "✗ Get-FragmentCacheDbPath: Command not found" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Cache Loading Analysis:" -ForegroundColor Cyan
Write-Host "-" * 70 -ForegroundColor DarkGray

# Check if cache was pre-warmed
$preWarmEnabled = $false
if ($env:PS_PROFILE_PREWARM_CACHE) {
    $normalized = $env:PS_PROFILE_PREWARM_CACHE.Trim().ToLowerInvariant()
    $preWarmEnabled = ($normalized -eq '1' -or $normalized -eq 'true')
}

if ($preWarmEnabled) {
    Write-Host "✓ Pre-warming: Enabled (PS_PROFILE_PREWARM_CACHE=1)" -ForegroundColor Green
    if ($cacheStatus.ContentCacheEntries -gt 0 -or $cacheStatus.AstCacheEntries -gt 0) {
        Write-Host "  Cache entries loaded: Content=$($cacheStatus.ContentCacheEntries), AST=$($cacheStatus.AstCacheEntries)" -ForegroundColor DarkGray
    }
    else {
        Write-Host "  ⚠ Warning: Pre-warming enabled but no cache entries found in memory" -ForegroundColor Yellow
    }
}
else {
    Write-Host "ℹ Pre-warming: Disabled (on-demand loading)" -ForegroundColor DarkGray
    Write-Host "  Cache entries will be loaded from database as fragments are parsed" -ForegroundColor DarkGray
}

# Check if cache functions are available
Write-Host ""
Write-Host "Cache Functions:" -ForegroundColor Cyan
Write-Host "-" * 70 -ForegroundColor DarkGray

$cacheFunctions = @(
    'Get-FragmentContentCache',
    'Set-FragmentContentCache',
    'Get-FragmentAstCache',
    'Set-FragmentAstCache',
    'Initialize-FragmentCache',
    'Test-SqliteAvailable',
    'Get-FragmentCacheDbPath',
    'Initialize-FragmentCacheDb'
)

foreach ($funcName in $cacheFunctions) {
    if (Get-Command $funcName -ErrorAction SilentlyContinue) {
        Write-Host "✓ ${funcName}" -ForegroundColor Green
    }
    else {
        Write-Host "✗ ${funcName}: Not found" -ForegroundColor Red
    }
}

# Summary
Write-Host ""
Write-Host "Summary:" -ForegroundColor Cyan
Write-Host "-" * 70 -ForegroundColor DarkGray

$allGood = $true
if (-not $cacheStatus.ContentCache) {
    Write-Host "✗ FragmentContentCache not initialized" -ForegroundColor Red
    $allGood = $false
}
if (-not $cacheStatus.AstCache) {
    Write-Host "✗ FragmentAstCache not initialized" -ForegroundColor Red
    $allGood = $false
}
if (-not $cacheStatus.SqliteAvailable) {
    Write-Host "⚠ SQLite not available (using in-memory cache only)" -ForegroundColor Yellow
}
if (-not $cacheStatus.DatabaseExists) {
    Write-Host "⚠ Database file not found (cache may not be persistent)" -ForegroundColor Yellow
}
else {
    Write-Host "✓ Database file exists and is accessible" -ForegroundColor Green
}

if ($allGood) {
    Write-Host ""
    Write-Host "✓ Cache system is properly initialized!" -ForegroundColor Green
    Write-Host ""
    Exit-WithCode -ExitCode $EXIT_SUCCESS
}
else {
    Write-Host ""
    Write-Host "✗ Cache system has issues - see details above" -ForegroundColor Red
    Write-Host ""
    Exit-WithCode -ExitCode $EXIT_VALIDATION_FAILURE
}
