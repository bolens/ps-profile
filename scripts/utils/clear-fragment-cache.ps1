<#
.SYNOPSIS
    Clears the fragment cache (in-memory and SQLite database).

.DESCRIPTION
    Clears all fragment cache data including:
    - In-memory caches (FragmentContentCache, FragmentAstCache)
    - SQLite database file (if it exists) - includes both AST and regex parsing cache entries
    - Module state variables
    
    The cache stores entries for both parsing modes:
    - AST parsing cache (ParsingMode='ast') - function definitions discovered via AST parsing
    - Regex parsing cache (ParsingMode='regex') - commands discovered via regex pattern matching
    
    Clearing the database removes both parsing mode caches. The script is resilient to failures
    and will continue clearing other cache components even if one component fails. Use -WhatIf
    to preview what would be cleared without actually clearing anything.

.PARAMETER WhatIf
    Shows what would be cleared without actually clearing anything (dry-run mode).

.PARAMETER Force
    Forces clearing even if some components fail. By default, the script continues
    on errors but reports them.

.PARAMETER IncludeDatabase
    If specified, includes the SQLite database file in the clearing operation.
    Default: $true

.PARAMETER IncludeMemoryCache
    If specified, includes in-memory caches in the clearing operation.
    Default: $true

.EXAMPLE
    pwsh -NoProfile -File scripts\utils\clear-fragment-cache.ps1
    
    Clears all fragment cache data.

.EXAMPLE
    pwsh -NoProfile -File scripts\utils\clear-fragment-cache.ps1 -WhatIf
    
    Shows what would be cleared without actually clearing anything.

.EXAMPLE
    pwsh -NoProfile -File scripts\utils\clear-fragment-cache.ps1 -IncludeDatabase:$false
    
    Clears only in-memory caches, leaving the database intact.
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [switch]$Force,
    
    [switch]$IncludeDatabase = $true,
    
    [switch]$IncludeMemoryCache = $true
)

# Import shared utilities directly (similar to run-pester.ps1)
# Calculate lib path manually to avoid circular dependency with Get-RepoRoot
# For scripts in scripts/utils/, calculate scripts dir manually
# $PSScriptRoot = scripts/utils, so go up 1 level to get scripts/
$scriptsDir = Split-Path -Parent $PSScriptRoot
$libPath = Join-Path $scriptsDir 'lib'

# Parse debug level once at script start
$debugLevel = 0
if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel)) {
    # Debug is enabled, $debugLevel contains the numeric level (1-3)
}

try {
    # Import core modules first (needed by others)
    $corePath = Join-Path $libPath 'core'
    
    # Import CommonEnums FIRST with -Global -Force to ensure enums are available globally
    # This is needed because Validation.psm1 (imported by SafeImport.psm1, imported by Logging.psm1)
    # uses FileSystemPathType in parameter definitions, which requires the type at parse time
    $commonEnumsPath = Join-Path $corePath 'CommonEnums.psm1'
    if (Test-Path -LiteralPath $commonEnumsPath) {
        Import-Module $commonEnumsPath -DisableNameChecking -ErrorAction Stop -Global -Force
    }
    
    Import-Module (Join-Path $corePath 'ExitCodes.psm1') -DisableNameChecking -ErrorAction Stop -Global -Force
    
    # Logging.psm1 is optional - script works without it (uses fallback error/warning functions)
    # But if available, import it (CommonEnums is already loaded above)
    $loggingPath = Join-Path $corePath 'Logging.psm1'
    if (Test-Path -LiteralPath $loggingPath) {
        Import-Module $loggingPath -DisableNameChecking -ErrorAction SilentlyContinue -Global -Force
    }
}
catch {
    Write-Error "Failed to import required modules: $_"
    exit 1
}

# Level 1: Basic operation start
if ($debugLevel -ge 1) {
    Write-Host "  [clear-fragment-cache] Starting fragment cache clearing operation" -ForegroundColor DarkGray
}

Write-Host "`nClearing Fragment Cache" -ForegroundColor Cyan
Write-Host "=======================" -ForegroundColor Cyan
Write-Host ""

# Statistics tracking
$stats = @{
    MemoryCacheCleared = 0
    MemoryCacheFailed  = 0
    DatabaseCleared    = 0
    DatabaseFailed     = 0
    ModuleStateCleared = 0
    ModuleStateFailed  = 0
    TotalOperations    = 0
    TotalSucceeded     = 0
    TotalFailed        = 0
}

# Helper function to handle errors consistently
function Write-CacheOperationError {
    param(
        [string]$OperationName,
        [string]$ErrorMessage,
        [string]$ErrorType,
        [hashtable]$Context = @{}
    )
    
    if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
        $errorRecord = New-Object System.Management.Automation.ErrorRecord(
            (New-Object System.Exception($ErrorMessage)),
            "CacheOperationFailed",
            [System.Management.Automation.ErrorCategory]::OperationStopped,
            $null
        )
        Write-StructuredError -ErrorRecord $errorRecord -OperationName "clear-fragment-cache.$OperationName" -Context $Context -StatusCode 500
    }
    else {
        Write-Host "  ✗ $OperationName failed: $ErrorMessage" -ForegroundColor Red
        if ($debugLevel -ge 2) {
            Write-Host "    [clear-fragment-cache] Error type: $ErrorType" -ForegroundColor DarkGray
        }
    }
}

# Helper function to handle warnings consistently
function Write-CacheOperationWarning {
    param(
        [string]$Message,
        [hashtable]$Context = @{}
    )
    
    if (Get-Command Write-StructuredWarning -ErrorAction SilentlyContinue) {
        Write-StructuredWarning -Message $Message -OperationName 'clear-fragment-cache' -Context $Context -Code 'CacheOperationWarning'
    }
    else {
        Write-Host "  ⚠ $Message" -ForegroundColor Yellow
    }
}

# Clear in-memory caches
if ($IncludeMemoryCache) {
    # FragmentContentCache
    $stats.TotalOperations++
    if ($PSCmdlet.ShouldProcess('FragmentContentCache', 'Clear in-memory cache')) {
        try {
            if (Get-Variable -Name 'FragmentContentCache' -Scope Global -ErrorAction SilentlyContinue) {
                $cacheSize = $global:FragmentContentCache.Count
                $global:FragmentContentCache.Clear()
                $stats.MemoryCacheCleared++
                $stats.TotalSucceeded++
                
                Write-Host "  ✓ Cleared FragmentContentCache ($cacheSize entries)" -ForegroundColor Green
                if ($debugLevel -ge 2) {
                    Write-Host "    [clear-fragment-cache] Cleared $cacheSize entries from FragmentContentCache" -ForegroundColor DarkGray
                }
            }
            else {
                Write-Host "  ⊘ FragmentContentCache not found (already cleared or not initialized)" -ForegroundColor Gray
            }
        }
        catch {
            $stats.MemoryCacheFailed++
            $stats.TotalFailed++
            Write-CacheOperationError -OperationName "Clear FragmentContentCache" -ErrorMessage $_.Exception.Message -ErrorType $_.Exception.GetType().FullName -Context @{
                cache_name = 'FragmentContentCache'
            }
            if (-not $Force) {
                Write-CacheOperationWarning -Message "Continuing with other cache clearing operations despite FragmentContentCache failure" -Context @{
                    failed_operation = 'FragmentContentCache'
                }
            }
        }
    }
    else {
        Write-Host "  [WhatIf] Would clear FragmentContentCache" -ForegroundColor Cyan
    }
    
    # FragmentAstCache
    $stats.TotalOperations++
    if ($PSCmdlet.ShouldProcess('FragmentAstCache', 'Clear in-memory cache')) {
        try {
            if (Get-Variable -Name 'FragmentAstCache' -Scope Global -ErrorAction SilentlyContinue) {
                $cacheSize = $global:FragmentAstCache.Count
                $global:FragmentAstCache.Clear()
                $stats.MemoryCacheCleared++
                $stats.TotalSucceeded++
                
                Write-Host "  ✓ Cleared FragmentAstCache ($cacheSize entries)" -ForegroundColor Green
                if ($debugLevel -ge 2) {
                    Write-Host "    [clear-fragment-cache] Cleared $cacheSize entries from FragmentAstCache" -ForegroundColor DarkGray
                }
            }
            else {
                Write-Host "  ⊘ FragmentAstCache not found (already cleared or not initialized)" -ForegroundColor Gray
            }
        }
        catch {
            $stats.MemoryCacheFailed++
            $stats.TotalFailed++
            Write-CacheOperationError -OperationName "Clear FragmentAstCache" -ErrorMessage $_.Exception.Message -ErrorType $_.Exception.GetType().FullName -Context @{
                cache_name = 'FragmentAstCache'
            }
            if (-not $Force) {
                Write-CacheOperationWarning -Message "Continuing with other cache clearing operations despite FragmentAstCache failure" -Context @{
                    failed_operation = 'FragmentAstCache'
                }
            }
        }
    }
    else {
        Write-Host "  [WhatIf] Would clear FragmentAstCache" -ForegroundColor Cyan
    }
}

# Try to use Clear-FragmentCache function if available
if ($IncludeDatabase) {
    $stats.TotalOperations++
    $cacheManagementModulePath = Join-Path $scriptsDir 'lib' 'fragment' 'FragmentCacheManagement.psm1'
    
    if ($PSCmdlet.ShouldProcess('FragmentCache database', 'Clear using Clear-FragmentCache function')) {
        if (Test-Path -LiteralPath $cacheManagementModulePath) {
            try {
                Import-Module $cacheManagementModulePath -DisableNameChecking -ErrorAction Stop -Force
                if (Get-Command Clear-FragmentCache -ErrorAction SilentlyContinue) {
                    if ($debugLevel -ge 2) {
                        Write-Host "  [clear-fragment-cache] Using Clear-FragmentCache function" -ForegroundColor DarkGray
                    }
                    
                    $clearResult = Clear-FragmentCache -IncludeDatabase $true
                    if ($clearResult) {
                        # Verify database was actually deleted
                        $dbPath = $null
                        if (Get-Command Get-FragmentCacheDbPath -ErrorAction SilentlyContinue) {
                            try {
                                $dbPath = Get-FragmentCacheDbPath
                                Start-Sleep -Milliseconds 100  # Brief pause for file system
                                if ($dbPath -and (Test-Path -LiteralPath $dbPath)) {
                                    Write-CacheOperationWarning -Message "Database file still exists after Clear-FragmentCache" -Context @{
                                        db_path = $dbPath
                                    }
                                    if ($debugLevel -ge 2) {
                                        Write-Host "    [clear-fragment-cache] ⚠ Warning: Database file still exists at: $dbPath" -ForegroundColor Yellow
                                    }
                                }
                                else {
                                    if ($debugLevel -ge 2) {
                                        Write-Host "    [clear-fragment-cache] ✓ Verified: Database file deleted successfully" -ForegroundColor Green
                                    }
                                }
                            }
                            catch {
                                # Ignore errors getting path for verification
                            }
                        }
                        
                        $stats.DatabaseCleared++
                        $stats.TotalSucceeded++
                        
                        Write-Host "  ✓ Cleared fragment cache using Clear-FragmentCache function" -ForegroundColor Green
                        Write-Host "    (Cleared both AST and regex parsing cache entries from database)" -ForegroundColor DarkGray
                        if ($debugLevel -ge 2) {
                            Write-Host "    [clear-fragment-cache] Clear-FragmentCache function completed successfully" -ForegroundColor DarkGray
                            Write-Host "    [clear-fragment-cache] Both ParsingMode='ast' and ParsingMode='regex' entries cleared" -ForegroundColor DarkGray
                        }
                    }
                    else {
                        Write-CacheOperationWarning -Message "Clear-FragmentCache returned false" -Context @{
                            module_path = $cacheManagementModulePath
                        }
                    }
                }
                else {
                    Write-CacheOperationWarning -Message "Clear-FragmentCache function not found after module import" -Context @{
                        module_path = $cacheManagementModulePath
                    }
                }
            }
            catch {
                $stats.DatabaseFailed++
                $stats.TotalFailed++
                Write-CacheOperationError -OperationName "Load FragmentCacheManagement module" -ErrorMessage $_.Exception.Message -ErrorType $_.Exception.GetType().FullName -Context @{
                    module_path = $cacheManagementModulePath
                }
                if (-not $Force) {
                    Write-CacheOperationWarning -Message "Continuing with fallback database clearing method" -Context @{
                        failed_operation = 'FragmentCacheManagement module import'
                    }
                }
            }
        }
        else {
            if ($debugLevel -ge 2) {
                Write-Host "  [clear-fragment-cache] FragmentCacheManagement module not found, using fallback method" -ForegroundColor DarkGray
            }
        }
    }
    else {
        Write-Host "  [WhatIf] Would clear fragment cache using Clear-FragmentCache function" -ForegroundColor Cyan
    }
}

# Fallback: manually delete database if function not available or failed
if ($IncludeDatabase -and ($stats.DatabaseCleared -eq 0)) {
    $stats.TotalOperations++
    if ($PSCmdlet.ShouldProcess('Fragment cache database file', 'Delete database file')) {
        try {
            # Try to get database path
            $dbPath = $null
            if (Get-Command Get-FragmentCacheDbPath -ErrorAction SilentlyContinue) {
                try {
                    $dbPath = Get-FragmentCacheDbPath
                    if ($debugLevel -ge 2) {
                        Write-Host "  [clear-fragment-cache] Database path from Get-FragmentCacheDbPath: $dbPath" -ForegroundColor DarkGray
                    }
                }
                catch {
                    Write-CacheOperationWarning -Message "Get-FragmentCacheDbPath function failed" -Context @{
                        error_message = $_.Exception.Message
                    }
                }
            }
            
            if (-not $dbPath) {
                # Try to determine path manually
                $cacheDir = if ($env:PS_PROFILE_CACHE_DIR) {
                    $env:PS_PROFILE_CACHE_DIR
                }
                elseif ($env:LOCALAPPDATA) {
                    Join-Path $env:LOCALAPPDATA 'PowerShellProfile'
                }
                else {
                    Join-Path $env:HOME '.cache' 'powershell-profile'
                }
                
                if ($cacheDir -and (Test-Path -LiteralPath $cacheDir)) {
                    $dbPath = Join-Path $cacheDir 'fragment-cache.db'
                    if ($debugLevel -ge 2) {
                        Write-Host "  [clear-fragment-cache] Database path determined manually: $dbPath" -ForegroundColor DarkGray
                    }
                }
            }
            
            if ($dbPath) {
                if (Test-Path -LiteralPath $dbPath) {
                    $fileInfo = Get-Item -LiteralPath $dbPath -ErrorAction SilentlyContinue
                    $fileSize = if ($fileInfo) { $fileInfo.Length } else { 0 }
                    
                    Remove-Item -LiteralPath $dbPath -Force -ErrorAction Stop
                    $stats.DatabaseCleared++
                    $stats.TotalSucceeded++
                    
                    Write-Host "  ✓ Deleted cache database: $dbPath" -ForegroundColor Green
                    Write-Host "    (Cleared both AST and regex parsing cache entries)" -ForegroundColor DarkGray
                    if ($debugLevel -ge 2) {
                        Write-Host "    [clear-fragment-cache] Database file size: $fileSize bytes" -ForegroundColor DarkGray
                        Write-Host "    [clear-fragment-cache] Both ParsingMode='ast' and ParsingMode='regex' entries cleared" -ForegroundColor DarkGray
                    }
                }
                else {
                    Write-Host "  ⊘ Cache database not found: $dbPath" -ForegroundColor Gray
                    if ($debugLevel -ge 2) {
                        Write-Host "    [clear-fragment-cache] Database file does not exist (already cleared or never created)" -ForegroundColor DarkGray
                    }
                }
            }
            else {
                Write-CacheOperationWarning -Message "Could not determine cache database path" -Context @{
                    cache_dir_env = $env:PS_PROFILE_CACHE_DIR
                    localappdata  = $env:LOCALAPPDATA
                    home          = $env:HOME
                }
            }
        }
        catch {
            $stats.DatabaseFailed++
            $stats.TotalFailed++
            Write-CacheOperationError -OperationName "Delete cache database" -ErrorMessage $_.Exception.Message -ErrorType $_.Exception.GetType().FullName -Context @{
                db_path = $dbPath
            }
            if (-not $Force) {
                Write-CacheOperationWarning -Message "Database deletion failed, but other cache components may have been cleared" -Context @{
                    failed_operation = 'Database deletion'
                }
            }
        }
    }
    else {
        Write-Host "  [WhatIf] Would delete cache database file" -ForegroundColor Cyan
    }
}

# Clear module state variables
$stats.TotalOperations++
if ($PSCmdlet.ShouldProcess('Module state variables', 'Clear module state')) {
    try {
        $moduleStateCleared = $false
        
        # Clear PSProfileModuleFileTimes if it exists
        if (Get-Variable -Name 'PSProfileModuleFileTimes' -Scope Global -ErrorAction SilentlyContinue) {
            $moduleStateCount = $global:PSProfileModuleFileTimes.Count
            $global:PSProfileModuleFileTimes.Clear()
            $moduleStateCleared = $true
            
            Write-Host "  ✓ Cleared PSProfileModuleFileTimes ($moduleStateCount entries)" -ForegroundColor Green
            if ($debugLevel -ge 2) {
                Write-Host "    [clear-fragment-cache] Cleared $moduleStateCount module file time entries" -ForegroundColor DarkGray
            }
        }
        
        if ($moduleStateCleared) {
            $stats.ModuleStateCleared++
            $stats.TotalSucceeded++
        }
        else {
            Write-Host "  ⊘ Module state variables not found (already cleared or not initialized)" -ForegroundColor Gray
        }
    }
    catch {
        $stats.ModuleStateFailed++
        $stats.TotalFailed++
        Write-CacheOperationError -OperationName "Clear module state variables" -ErrorMessage $_.Exception.Message -ErrorType $_.Exception.GetType().FullName
        if (-not $Force) {
            Write-CacheOperationWarning -Message "Module state clearing failed, but other cache components may have been cleared" -Context @{
                failed_operation = 'Module state clearing'
            }
        }
    }
}
else {
    Write-Host "  [WhatIf] Would clear module state variables" -ForegroundColor Cyan
}

# Summary
Write-Host ""
if ($PSCmdlet.ShouldProcess('Summary', 'Display summary')) {
    if ($stats.TotalSucceeded -gt 0 -or $stats.TotalFailed -eq 0) {
        Write-Host "Fragment cache clearing completed!" -ForegroundColor Green
    }
    else {
        Write-Host "Fragment cache clearing completed with errors" -ForegroundColor Yellow
    }
    
    # Level 2: Detailed statistics
    if ($debugLevel -ge 2) {
        Write-Host ""
        Write-Host "  [clear-fragment-cache] Summary statistics:" -ForegroundColor DarkGray
        Write-Host "    [clear-fragment-cache]   Total operations: $($stats.TotalOperations)" -ForegroundColor DarkGray
        Write-Host "    [clear-fragment-cache]   Succeeded: $($stats.TotalSucceeded)" -ForegroundColor Green
        if ($stats.TotalFailed -gt 0) {
            Write-Host "    [clear-fragment-cache]   Failed: $($stats.TotalFailed)" -ForegroundColor Red
        }
        Write-Host "    [clear-fragment-cache]   Memory cache cleared: $($stats.MemoryCacheCleared)" -ForegroundColor Blue
        Write-Host "    [clear-fragment-cache]   Database cleared: $($stats.DatabaseCleared) (both AST and regex cache entries)" -ForegroundColor Blue
        Write-Host "    [clear-fragment-cache]   Module state cleared: $($stats.ModuleStateCleared)" -ForegroundColor Blue
    }
    
    # Exit with appropriate code
    # Use constants directly - PowerShell should convert int to enum automatically
    if ($stats.TotalFailed -gt 0 -and -not $Force) {
        Exit-WithCode -ExitCode $EXIT_OTHER_ERROR -Message "Cache clearing completed with $($stats.TotalFailed) failure(s)"
    }
    elseif ($stats.TotalSucceeded -eq 0 -and $stats.TotalOperations -gt 0) {
        Exit-WithCode -ExitCode $EXIT_VALIDATION_FAILURE -Message "No cache components were cleared (all were already empty or not found)"
    }
    else {
        Exit-WithCode -ExitCode $EXIT_SUCCESS
    }
}
else {
    Write-Host ""
    Write-Host "[WhatIf] Summary: Would attempt to clear $($stats.TotalOperations) cache component(s)" -ForegroundColor Cyan
    Exit-WithCode -ExitCode $EXIT_SUCCESS
}
