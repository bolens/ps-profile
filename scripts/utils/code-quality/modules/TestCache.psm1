<#
scripts/utils/code-quality/modules/TestCache.psm1

.SYNOPSIS
    Test result caching utilities for the PowerShell profile test runner.

.DESCRIPTION
    Provides functions for caching test results based on file hashes and timestamps
    to avoid re-running unchanged tests, significantly improving CI performance.
    Uses SQLite database for persistent storage when available, falls back to JSON files.
#>

# Import Logging module for Write-ScriptMessage
$loggingModulePath = Join-Path (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)))) 'lib' 'core' 'Logging.psm1'
if ($loggingModulePath -and -not [string]::IsNullOrWhiteSpace($loggingModulePath) -and (Test-Path -LiteralPath $loggingModulePath)) {
    Import-Module $loggingModulePath -DisableNameChecking -ErrorAction SilentlyContinue
}

# Try to import SQLite test cache database module
$testCacheDbModule = Join-Path (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)))) 'lib' 'database' 'TestCacheDatabase.psm1'
$script:UseSqliteCache = $false
if ($testCacheDbModule -and (Test-Path -LiteralPath $testCacheDbModule)) {
    try {
        Import-Module $testCacheDbModule -DisableNameChecking -ErrorAction SilentlyContinue
        if (Get-Command Get-TestCache -ErrorAction SilentlyContinue) {
            $script:UseSqliteCache = $true
        }
    }
    catch {
        # SQLite cache not available, fall back to JSON
    }
}

<#
.SYNOPSIS
    Manages test result caching for improved performance.

.DESCRIPTION
    Caches test results based on file hashes and timestamps to avoid
    re-running unchanged tests, significantly improving CI performance.

.PARAMETER CachePath
    Path to the cache directory.

.PARAMETER TestPaths
    Array of test file paths to check for cache validity.

.PARAMETER Force
    Force cache invalidation and fresh test execution.

.OUTPUTS
    Cache status information
#>
function Get-TestCacheStatus {
    param(
        [string]$CachePath = '.pester-cache',
        [string[]]$TestPaths,
        [switch]$Force
    )

    $cacheStatus = @{
        CachePath     = $CachePath
        IsValid       = $false
        CachedResults = $null
        Reason        = $null
    }

    if ($Force) {
        $cacheStatus.Reason = 'Cache forced to invalidate'
        return $cacheStatus
    }

    # Try SQLite cache first if available
    if ($script:UseSqliteCache -and $TestPaths -and $TestPaths.Count -gt 0) {
        try {
            # Check cache for first test file (for compatibility with existing interface)
            $firstTestPath = $TestPaths[0]
            if ($firstTestPath -and (Test-Path -LiteralPath $firstTestPath)) {
                $cached = Get-TestCache -TestFilePath $firstTestPath
                if ($cached -and $cached.IsValid) {
                    $cacheStatus.IsValid = $true
                    $cacheStatus.CachedResults = $cached.TestResult
                    $cacheStatus.Reason = 'Cache is valid (SQLite)'
                    return $cacheStatus
                }
                else {
                    $cacheStatus.Reason = 'Cache invalid or not found (SQLite)'
                    return $cacheStatus
                }
            }
        }
        catch {
            # Fall through to JSON cache
            if ($env:PS_PROFILE_DEBUG) {
                Write-Host "  [TestCache] SQLite cache failed, falling back to JSON: $($_.Exception.Message)" -ForegroundColor DarkGray
            }
        }
    }

    # Fall back to JSON cache
    if ($CachePath -and -not [string]::IsNullOrWhiteSpace($CachePath) -and -not (Test-Path -LiteralPath $CachePath)) {
        $cacheStatus.Reason = 'Cache directory does not exist'
        return $cacheStatus
    }

    $cacheFile = Join-Path $CachePath 'results.cache'
    if ($cacheFile -and -not [string]::IsNullOrWhiteSpace($cacheFile) -and -not (Test-Path -LiteralPath $cacheFile)) {
        $cacheStatus.Reason = 'Cache file does not exist'
        return $cacheStatus
    }

    try {
        $cachedData = Get-Content $cacheFile -Raw | ConvertFrom-Json

        # Check if test files have changed
        $cacheValid = $true
        foreach ($testPath in $TestPaths) {
            if ($testPath -and -not [string]::IsNullOrWhiteSpace($testPath) -and (Test-Path -LiteralPath $testPath)) {
                $fileHash = Get-FileHash $testPath -Algorithm SHA256
                $cachedHash = $cachedData.FileHashes.$testPath

                if (-not $cachedHash -or $fileHash.Hash -ne $cachedHash) {
                    $cacheValid = $false
                    $cacheStatus.Reason = "File $testPath has changed"
                    break
                }
            }
        }

        if ($cacheValid) {
            $cacheStatus.IsValid = $true
            $cacheStatus.CachedResults = $cachedData.Results
            $cacheStatus.Reason = 'Cache is valid'
        }
    }
    catch {
        $cacheStatus.Reason = "Failed to read cache: $($_.Exception.Message)"
    }

    return $cacheStatus
}

<#
.SYNOPSIS
    Saves test results to cache.

.DESCRIPTION
    Stores test results along with file hashes for future cache validation.

.PARAMETER TestResult
    The Pester test result object.

.PARAMETER TestPaths
    Array of test file paths that were executed.

.PARAMETER CachePath
    Path to the cache directory.

.OUTPUTS
    None
#>
function Save-TestCache {
    param(
        $TestResult,
        [string[]]$TestPaths,
        [string]$CachePath = '.pester-cache'
    )

    # Try SQLite cache first if available
    if ($script:UseSqliteCache -and $TestPaths -and $TestPaths.Count -gt 0) {
        try {
            foreach ($testPath in $TestPaths) {
                if ($testPath -and (Test-Path -LiteralPath $testPath)) {
                    # Extract counts from test result
                    $passedCount = if ($TestResult.PassedCount) { $TestResult.PassedCount } else { 0 }
                    $failedCount = if ($TestResult.FailedCount) { $TestResult.FailedCount } else { 0 }
                    $skippedCount = if ($TestResult.SkippedCount) { $TestResult.SkippedCount } else { 0 }
                    $executionTime = if ($TestResult.Time) { $TestResult.Time.TotalSeconds } elseif ($TestResult.Duration) { $TestResult.Duration.TotalSeconds } else { 0 }
                    
                    Save-TestCache -TestFilePath $testPath -TestResult $TestResult -ExecutionTime $executionTime -PassedCount $passedCount -FailedCount $failedCount -SkippedCount $skippedCount
                }
            }
            Write-ScriptMessage -Message "Test results cached to SQLite database"
            return
        }
        catch {
            # Fall through to JSON cache
            if ($env:PS_PROFILE_DEBUG) {
                Write-Host "  [TestCache] SQLite cache save failed, falling back to JSON: $($_.Exception.Message)" -ForegroundColor DarkGray
            }
        }
    }

    # Fall back to JSON cache
    try {
        if ($CachePath -and -not [string]::IsNullOrWhiteSpace($CachePath) -and -not (Test-Path -LiteralPath $CachePath)) {
            New-Item -ItemType Directory -Path $CachePath -Force | Out-Null
        }

        $fileHashes = @{}
        foreach ($testPath in $TestPaths) {
            if ($testPath -and -not [string]::IsNullOrWhiteSpace($testPath) -and (Test-Path -LiteralPath $testPath)) {
                $fileHash = Get-FileHash $testPath -Algorithm SHA256
                $fileHashes[$testPath] = $fileHash.Hash
            }
        }

        $cacheData = @{
            Timestamp  = Get-Date
            FileHashes = $fileHashes
            Results    = $TestResult
        }

        $cacheFile = Join-Path $CachePath 'results.cache'
        $cacheData | ConvertTo-Json -Depth 10 | Out-File $cacheFile -Encoding UTF8

        Write-ScriptMessage -Message "Test results cached to $cacheFile"
    }
    catch {
        Write-ScriptMessage -Message "Failed to save test cache: $($_.Exception.Message)" -LogLevel 'Warning'
    }
}

Export-ModuleMember -Function @(
    'Get-TestCacheStatus',
    'Save-TestCache'
)

