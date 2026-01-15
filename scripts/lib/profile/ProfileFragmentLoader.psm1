<#
.SYNOPSIS
    Fragment loading logic for profile initialization.

.DESCRIPTION
    Loads profile fragments sequentially or in parallel batches (by dependency level)
    and records batch loading information for end-of-run summaries.

    This module is designed to be invoked by `Microsoft.PowerShell_profile.ps1`.
#>

$script:BatchProgressHeaderShown = $false

# Initialize module file modification time cache
if (-not (Get-Variable -Name 'PSProfileModuleFileTimes' -Scope Global -ErrorAction SilentlyContinue)) {
    $global:PSProfileModuleFileTimes = @{}
}

<#
.SYNOPSIS
    Checks if a module file has changed since it was last loaded and reloads if necessary.

.DESCRIPTION
    Compares the current file modification time with the cached modification time.
    If the file has changed, removes the module and forces a reload.

.PARAMETER ModulePath
    Path to the module file to check.

.PARAMETER ModuleName
    Name of the module to check/reload.

.PARAMETER HasDebug
    Boolean indicating if debug output should be shown.

.PARAMETER DebugLevel
    Debug level (0-3) for controlling output verbosity.

.OUTPUTS
    System.Boolean. True if module was reloaded, False otherwise.
#>
function Test-AndReloadModuleIfChanged {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory)]
        [string]$ModulePath,

        [Parameter(Mandatory)]
        [string]$ModuleName,

        [bool]$HasDebug = $false,

        [int]$DebugLevel = 0
    )

    if (-not (Test-Path -LiteralPath $ModulePath)) {
        return $false
    }

    # Get current file modification time
    $fileInfo = Get-Item -LiteralPath $ModulePath -ErrorAction SilentlyContinue
    if (-not $fileInfo) {
        return $false
    }

    $currentWriteTime = $fileInfo.LastWriteTimeUtc.Ticks
    $cacheKey = $ModulePath

    # Check if module is loaded
    $loadedModule = Get-Module -Name $ModuleName -ErrorAction SilentlyContinue

    # Check if file has changed
    $needsReload = $false
    if ($global:PSProfileModuleFileTimes.ContainsKey($cacheKey)) {
        $cachedWriteTime = $global:PSProfileModuleFileTimes[$cacheKey]
        if ($currentWriteTime -ne $cachedWriteTime) {
            $needsReload = $true
            if ($HasDebug -and $DebugLevel -ge 2) {
                Write-Host "  [profile-fragment-loader] Module file changed: $ModuleName (reloading...)" -ForegroundColor DarkGray
            }
        }
    }
    else {
        # First time loading - cache the write time
        $needsReload = $false
    }

    # If module is loaded and file changed, remove it first
    if ($needsReload -and $loadedModule) {
        if ($HasDebug -and $DebugLevel -ge 2) {
            Write-Host "  [profile-fragment-loader] Removing cached module: $ModuleName" -ForegroundColor DarkGray
        }
        Remove-Module -Name $ModuleName -ErrorAction SilentlyContinue -Force
    }

    # Update cached write time
    $global:PSProfileModuleFileTimes[$cacheKey] = $currentWriteTime

    return $needsReload
}

function Write-BatchProgressTableHeader {
    [CmdletBinding()]
    param()

    if ($script:BatchProgressHeaderShown) {
        Write-Host ""
        return
    }

    $script:BatchProgressHeaderShown = $true
    Write-Host ""
    Write-Host ("{0,-7} {1,9} {2,9} {3}" -f 'Batch', 'Fragments', 'Progress', 'Names') -ForegroundColor Cyan
    Write-Host ("{0,-7} {1,9} {2,9} {3}" -f '-----', '---------', '--------', '-----') -ForegroundColor Cyan
}

function Write-BatchProgressRow {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [int]$BatchNumber,

        [Parameter(Mandatory)]
        [int]$TotalBatches,

        [Parameter(Mandatory)]
        [int]$FragmentCount,

        [Parameter(Mandatory)]
        [string[]]$FragmentNames
    )

    $progressPercent = if ($TotalBatches -gt 0) { [Math]::Round(($BatchNumber / $TotalBatches) * 100) } else { 0 }
    $batchLabel = ('{0}/{1}' -f $BatchNumber, $TotalBatches)
    $progressLabel = ('{0}%' -f $progressPercent)

    $names = @($FragmentNames)
    $maxNames = 10
    $namesStr = if ($names.Count -le $maxNames) {
        ($names -join ', ')
    }
    else {
        $firstFew = ($names[0..($maxNames - 1)] -join ', ')
        "$firstFew, … (+$($names.Count - $maxNames) more)"
    }

    Write-Host ("{0,-7} {1,9} {2,9} {3}" -f $batchLabel, $FragmentCount, $progressLabel, $namesStr) -ForegroundColor Cyan
}

function Initialize-FragmentLoading {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [System.Collections.Generic.List[System.IO.FileInfo]]$FragmentsToLoad,

        [Parameter(Mandatory = $false)]
        [System.IO.FileInfo[]]$BootstrapFragment = @(),

        [Parameter(Mandatory = $false)]
        [AllowNull()]
        [System.Collections.Generic.HashSet[string]]$DisabledSet = $null,

        [Parameter(Mandatory = $false)]
        [AllowEmptyCollection()]
        [string[]]$DisabledFragments = @(),

        [Parameter(Mandatory)]
        [bool]$EnableParallelLoading,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$FragmentLoadingModule,

        [Parameter(Mandatory)]
        [bool]$FragmentLoadingModuleExists,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$FragmentLibDir,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$FragmentErrorHandlingModule,

        [Parameter(Mandatory)]
        [bool]$FragmentErrorHandlingModuleExists,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$ProfileD
    )

    # Parse debug level early for diagnostics
    # Note: VerbosePreference is automatically set to 'Continue' by GlobalState.ps1 when PS_PROFILE_DEBUG >= 1
    $debugLevel = 0
    $hasDebug = $false
    if ($env:PS_PROFILE_DEBUG) {
        if ([int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel)) {
            $hasDebug = $debugLevel -gt 0
        }
    }
    
    # Diagnostic: Confirm function is being called (consolidated, no duplicates)
    if ($hasDebug -and $debugLevel -ge 1) {
        Write-Host ""
        Write-Host "[profile-fragment-loader] Initialize-FragmentLoading called (debug level: $debugLevel)" -ForegroundColor Cyan
        if ($debugLevel -ge 2) {
            Write-Host "  [profile-fragment-loader] FragmentsToLoad.Count: $($FragmentsToLoad.Count)" -ForegroundColor DarkGray
            Write-Host "  [profile-fragment-loader] BootstrapFragment.Count: $($BootstrapFragment.Count)" -ForegroundColor DarkGray
            Write-Host "  [profile-fragment-loader] FragmentLibDir: $FragmentLibDir" -ForegroundColor DarkGray
            Write-Host "  [profile-fragment-loader] ProfileD: $ProfileD" -ForegroundColor DarkGray
        }
    }

    $script:BatchProgressHeaderShown = $false
    $global:PSProfileDependencyAnalysisShown = $false

    $dependencyParsingTimeMs = $null
    $dependencyLevelsCount = $null

    $fragmentLevels = $null
    $useParallelLoading = $false
    $parallelLoadingModuleLoaded = $false

    # Track results across bootstrap + normal fragments
    $allSucceeded = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
    $allFailed = [System.Collections.Generic.List[hashtable]]::new()
    $failedNames = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
    
    # Initialize fragment tracking for consolidated output (if not already initialized)
    if (-not $script:LoadedFragments) {
        $script:LoadedFragments = [System.Collections.Generic.List[string]]::new()
    }
    else {
        $script:LoadedFragments.Clear()
    }
    if (-not $script:FragmentLoadingBatchSize) {
        $script:FragmentLoadingBatchSize = 10  # Show fragments in batches of 10
    }
    
    # Delegate to cache initialization module if available
    $cacheInitModule = Get-Module ProfileFragmentCacheInitialization -ErrorAction SilentlyContinue
    $cacheInitModulePath = Join-Path $PSScriptRoot 'ProfileFragmentCacheInitialization.psm1'
    
    # Check if module file has changed and reload if necessary
    if (Test-Path -LiteralPath $cacheInitModulePath) {
        $needsReload = Test-AndReloadModuleIfChanged -ModulePath $cacheInitModulePath -ModuleName 'ProfileFragmentCacheInitialization' -HasDebug $hasDebug -DebugLevel $debugLevel
        if (-not $cacheInitModule -or $needsReload) {
            # Try to import cache initialization module
            Import-Module $cacheInitModulePath -DisableNameChecking -ErrorAction SilentlyContinue -Force
            $cacheInitModule = Get-Module ProfileFragmentCacheInitialization -ErrorAction SilentlyContinue
        }
    }
    
    if ($cacheInitModule) {
        $cacheInitCmd = Get-Command -Module ProfileFragmentCacheInitialization Initialize-FragmentCacheForLoading -ErrorAction SilentlyContinue
        if ($cacheInitCmd) {
            # Call cache initialization function
            $null = & $cacheInitCmd -FragmentLibDir $FragmentLibDir -HasDebug $hasDebug -DebugLevel $debugLevel
        }
    }
    
    # Fallback: If cache initialization module is not available, use inline implementation
    if (-not $cacheInitModule -or -not (Get-Command -Module ProfileFragmentCacheInitialization Initialize-FragmentCacheForLoading -ErrorAction SilentlyContinue)) {
        # Fallback implementation (simplified)
        $fragmentCacheModule = Join-Path $FragmentLibDir 'FragmentCache.psm1'
        if (Test-Path -LiteralPath $fragmentCachele) {
            try {
                # Check if module file has changed and reload if necessary
                $needsReload = Test-AndReloadModuleIfChanged -ModulePath $fragmentCachele -ModuleName 'FragmentCache' -Hbug -DebugLevel $debugLevel
                if ($needsReload -or -not (Get-Module FragmentCacheSilentlyContinue)) {
                    Import-Module $fragmentCachele -DisableNameChecking -ErrorAction SilentlyContinue -Force
                }
                if (Get-Command Initialize-FragmentCache -ErrorAction SilentlyContinue) {
                    # Suppress return value
                    [void](Initialize-FragmentCache)
                }
            }
            catch {
                # Cache initialization failure shouldn't block profile loading
            }
        }
        # Initialize in-memory cache as fallback
        if (-not (Get-Variable -Name 'FragmentContentCache' -Scope Global -ErrorAction SilentlyContinue)) {
            $global:FragmentContentCache = @{}
        }
        if (-not (Get-Variable -Name 'FragmentAstCache' -Scope Global -ErrorAction SilentlyContinue)) {
            $global:FragmentAstCache = @{}
        }
    }

    # Load bootstrap fragments using dedicated module if available
    $bootstrapModulePath = Join-Path $PSScriptRoot 'ProfileFragmentBootstrap.psm1'
    $bootstrapModule = $null
    $bootstrapNameSet = $null
    
    if (Test-Path -LiteralPath $bootstrapModulePath) {
        try {
            Import-Module $bootstrapModulePath -DisableNameChecking -ErrorAction SilentlyContinue -Force
            $bootstrapModule = Get-Module ProfileFragmentBootstrap -ErrorAction SilentlyContinue
            if ($bootstrapModule -and (Get-Command Invoke-BootstrapFragmentLoading -ErrorAction SilentlyContinue)) {
                $bootstrapCmd = Get-Command -Module ProfileFragmentBootstrap Invoke-BootstrapFragmentLoading -ErrorAction SilentlyContinue
                if ($bootstrapCmd) {
                    $bootstrapNameSet = & $bootstrapCmd -BootstrapFragment $BootstrapFragment -AllSucceeded $allSucceeded -AllFailed $allFailed -FailedNames $failedNames
                }
            }
        }
        catch {
            # Fall through to inline loading
        }
    }
    
    # Fallback to inline bootstrap loading if module not available or failed
    if (-not $bootstrapNameSet) {
        # Treat bootstrap as a pre-stage: load first, but do NOT include in batch numbering
        $bootstrapNameSet = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
        foreach ($bf in @($BootstrapFragment)) {
            if ($bf -and $bf.BaseName) { 
                [void]$bootstrapNameSet.Add($bf.BaseName) 
            }
        }
        # Also exclude files-module-registry since it loads at the same time as bootstrap
        [void]$bootstrapNameSet.Add('files-module-registry')

        foreach ($bf in @($BootstrapFragment)) {
            if (-not $bf) { continue }
            try {
                $null = . $bf.FullName
                if ($bf.BaseName) { 
                    [void]$allSucceeded.Add($bf.BaseName) 
                }
            }
            catch {
                $debugLevel = 0
                if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel) -and $debugLevel -ge 1) {
                    if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                        Write-StructuredError -ErrorRecord $_ -OperationName 'profile-fragment-loader.bootstrap' -Context @{
                            FragmentName = $bf.Name
                            FragmentPath = $bf.FullName
                        }
                    }
                    else {
                        Write-Error "[profile-fragment-loader.bootstrap] Failed to load bootstrap fragment '$($bf.Name)': $($_.Exception.Message)"
                    }
                }
                # Level 3: Log detailed error information
                if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel) -and $debugLevel -ge 3) {
                    Write-Host "  [profile-fragment-loader.bootstrap] Bootstrap load error details - FragmentName: $($bf.Name), FragmentPath: $($bf.FullName), Exception: $($_.Exception.GetType().FullName), Message: $($_.Exception.Message)" -ForegroundColor DarkGray
                }
                else {
                    # Always log critical errors even if debug is off
                    if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                        Write-StructuredError -ErrorRecord $_ -OperationName 'profile-fragment-loader.bootstrap' -Context @{
                            # Technical context
                            FragmentName     = $bf.Name
                            FragmentPath     = $bf.FullName
                            FragmentBaseName = $bf.BaseName
                            # Error context
                            ErrorType        = $_.Exception.GetType().FullName
                            # Invocation context
                            FunctionName     = 'Initialize-FragmentLoading'
                        }
                    }
                    else {
                        Write-Error "[profile-fragment-loader.bootstrap] Failed to load bootstrap fragment '$($bf.Name)': $($_.Exception.Message)"
                    }
                }
                if ($bf.BaseName -and -not $failedNames.Contains($bf.BaseName)) {
                    $allFailed.Add(@{ Name = $bf.BaseName; Error = $_.Exception.Message })
                    [void]$failedNames.Add($bf.BaseName)
                }
            }
        }
    }

    # Initialize batch summary tracking after bootstrap is available
    if (Get-Command Initialize-BatchLoadingInfo -ErrorAction SilentlyContinue) {
        Initialize-BatchLoadingInfo
    }
    if (Get-Command Set-TotalFragmentCount -ErrorAction SilentlyContinue) {
        Set-TotalFragmentCount -Count $FragmentsToLoad.Count
    }

    # Delegate to cache initialization module for pre-warming if available
    $cacheInitModule = Get-Module ProfileFragmentCacheInitialization -ErrorAction SilentlyContinue
    if (-not $cacheInitModule) {
        $cacheInitModulePath = Join-Path $PSScriptRoot 'ProfileFragmentCacheInitialization.psm1'
        if (Test-Path -LiteralPath $cacheInitModulePath) {
            Import-Module $cacheInitModulePath -DisableNameChecking -ErrorAction SilentlyContinue -Force
            $cacheInitModule = Get-Module ProfileFragmentCacheInitialization -ErrorAction SilentlyContinue
        }
    }
    
    if ($cacheInitModule) {
        $preWarmCmd = Get-Command -Module ProfileFragmentCacheInitialization Pre-WarmFragmentCache -ErrorAction SilentlyContinue
        if ($preWarmCmd) {
            # Call pre-warming function
            # Suppress return value to prevent "True" from being displayed
            [void](& $preWarmCmd -FragmentsToLoad $FragmentsToLoad -HasDebug $hasDebug -DebugLevel $debugLevel)
        }
    }
    
    # Fallback: If cache initialization module is not available, use inline implementation
    if (-not $cacheInitModule -or -not (Get-Command -Module ProfileFragmentCacheInitialization Pre-WarmFragmentCache -ErrorAction SilentlyContinue)) {
        # Fallback implementation (simplified)
        $preWarmEnabled = $false
        if ($env:PS_PROFILE_PREWARM_CACHE) {
            $normalized = $env:PS_PROFILE_PREWARM_CACHE.Trim().ToLowerInvariant()
            $preWarmEnabled = ($normalized -eq '1' -or $normalized -eq 'true')
        }
        
        if ($preWarmEnabled -and $FragmentsToLoad.Count -gt 0) {
            # Note: We always use both AST and regex parsing now (handled by Register-AllFragmentCommands with ForceBothParsingModes)
            # The UseAstParsing parameter is deprecated but kept for backward compatibility
            $sqliteAvailable = $false
            if (Get-Command Test-SqliteAvailable -ErrorAction SilentlyContinue) {
                $null = $sqliteAvailable = Test-SqliteAvailable
            }
            if ($sqliteAvailable) {
                try {
                    # Pre-warming happens silently - no status messages unless there's an error
                    # Suppress return value to prevent "True" from being displayed
                    # Note: UseAstParsing parameter is deprecated - we always parse with both modes
                    [void](Initialize-FragmentCache -FragmentFiles $FragmentsToLoad.ToArray() -UseAstParsing $true)
                }
                catch {
                    # Use structured error handling
                    if (Get-Command Write-StructuredWarning -ErrorAction SilentlyContinue) {
                        Write-StructuredWarning -Message "Cache pre-warming failed, continuing with on-demand loading" -OperationName 'profile-fragment-loader.cache-prewarm' -Context @{
                            fragment_count = $FragmentsToLoad.Count
                            error_message  = $_.Exception.Message
                        } -Code 'CachePreWarmFailed'
                    }
                    else {
                        # Fallback to Write-Warning
                        Write-Warning "[profile-fragment-loader] Cache pre-warming failed: $($_.Exception.Message) (continuing with on-demand loading)"
                    }
                    
                    # Additional debug details at Level 2+
                    if ($hasDebug -and $debugLevel -ge 2) {
                        Write-Host "  [profile-fragment-loader] Cache pre-warming error details: $($_.Exception.GetType().FullName)" -ForegroundColor DarkGray
                    }
                }
            }
        }
    }

    # Check if lazy loading is enabled (skip fragment loading, rely on on-demand loading)
    # Default: lazy loading is ENABLED (fragments load on-demand)
    # This needs to be determined before pre-registration to know if it should be skipped
    $lazyLoadEnabled = $true
    
    # Check explicit lazy load setting (takes precedence)
    if ($env:PS_PROFILE_LAZY_LOAD_FRAGMENTS) {
        $normalized = $env:PS_PROFILE_LAZY_LOAD_FRAGMENTS.Trim().ToLowerInvariant()
        $lazyLoadEnabled = ($normalized -eq '1' -or $normalized -eq 'true')
    }
    # Check inverse: if PS_PROFILE_LOAD_ALL_FRAGMENTS is explicitly set to true, disable lazy loading
    elseif ($env:PS_PROFILE_LOAD_ALL_FRAGMENTS) {
        $normalized = $env:PS_PROFILE_LOAD_ALL_FRAGMENTS.Trim().ToLowerInvariant()
        $lazyLoadEnabled = -not ($normalized -eq '1' -or $normalized -eq 'true')
    }

    # Use pre-registration module if available
    $preRegistrationModulePath = Join-Path $PSScriptRoot 'ProfileFragmentPreRegistration.psm1'
    $preRegistrationModule = $null
    $preRegisterStats = $null
    
    if (Test-Path -LiteralPath $preRegistrationModulePath) {
        $oldVerbosePreference = $null
        try {
            # Temporarily suppress PowerShell's Import-Module verbose messages
            $oldVerbosePreference = $VerbosePreference
            $VerbosePreference = 'SilentlyContinue'
            Import-Module $preRegistrationModulePath -DisableNameChecking -ErrorAction SilentlyContinue -Force
            $VerbosePreference = $oldVerbosePreference
            $preRegistrationModule = Get-Module ProfileFragmentPreRegistration -ErrorAction SilentlyContinue
            if ($preRegistrationModule -and (Get-Command Invoke-FragmentCommandPreRegistration -ErrorAction SilentlyContinue)) {
                $preRegCmd = Get-Command -Module ProfileFragmentPreRegistration Invoke-FragmentCommandPreRegistration -ErrorAction SilentlyContinue
                if ($preRegCmd) {
                    $preRegisterStats = & $preRegCmd -FragmentsToLoad $FragmentsToLoad -FragmentLibDir $FragmentLibDir -ProfileD $ProfileD
                }
            }
        }
        catch {
            # Restore VerbosePreference if it was changed
            if ($null -ne $oldVerbosePreference) {
                $VerbosePreference = $oldVerbosePreference
            }
            # Fall through to inline pre-registration logic
            if ($hasDebug -and $debugLevel -ge 1) {
                Write-Host "  [profile-fragment-loader] Pre-registration module failed, falling back to inline logic: $($_.Exception.Message)" -ForegroundColor Yellow
            }
        }
    }
    
    # Fallback to inline pre-registration if module not available or failed
    if (-not $preRegisterStats -and $FragmentsToLoad.Count -gt 0) {
            
        # Check explicit lazy load setting (takes precedence)
        # Warning: fallback to inline logic
        if ($hasDebug -and $debugLevel -ge 2) {
            Write-Host "  [profile-fragment-loader] Pre-registration module failed, falling back to inline logic: $($_.Exception.Message)" -ForegroundColor DarkGray
        }
        $normalized = $env:PS_PROFILE_LAZY_LOAD_FRAGMENTS.Trim().ToLowerInvariant()
        $lazyLoadEnabled = ($normalized -eq '1' -or $normalized -eq 'true')
    }
    # Check inverse: if PS_PROFILE_LOAD_ALL_FRAGMENTS is explicitly set to true, disable lazy loading
    elseif ($env:PS_PROFILE_LOAD_ALL_FRAGMENTS) {
        $normalized = $env:PS_PROFILE_LOAD_ALL_FRAGMENTS.Trim().ToLowerInvariant()
        $lazyLoadEnabled = -not ($normalized -eq '1' -or $normalized -eq 'true')
    }

    # Pre-register commands from fragments using AST parsing (if enabled)
    # This enables on-demand fragment loading by populating the registry before fragments are loaded
    # NOTE: If lazy loading is disabled, we don't need pre-registration (fragments will load anyway)
    $preRegisterEnabled = $true
    if ($env:PS_PROFILE_PRE_REGISTER_COMMANDS) {
        $normalized = $env:PS_PROFILE_PRE_REGISTER_COMMANDS.Trim().ToLowerInvariant()
        $preRegisterEnabled = ($normalized -eq '1' -or $normalized -eq 'true')
    }
            
    # Skip pre-registration if lazy loading is disabled (fragments will load anyway, so registry will be populated)
    if (-not $lazyLoadEnabled) {
        $preRegisterEnabled = $false
        $debugLevel = 0
        if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel) -and $debugLevel -ge 2) {
            Write-Host "[profile-fragment-loader.pre-register] Lazy loading disabled - skipping pre-registration (fragments will load and register commands normally)" -ForegroundColor DarkGray
        }
    }
            
    if ($preRegisterEnabled) {
        # Ensure FragmentCommandParserOrchestration module is loaded (contains Register-AllFragmentCommands)
        $orchestrationModulePath = Join-Path $FragmentLibDir 'FragmentCommandParserOrchestration.psm1'
            
        # Fallback: if path doesn't exist, try to resolve from PSScriptRoot or ProfileD
        if (-not (Test-Path -LiteralPath $orchestrationModulePath)) {
            # Try to resolve from ProfileD (go up one level to repo root, then scripts/lib/fragment)
            if ($ProfileD -and (Test-Path -LiteralPath $ProfileD)) {
                $repoRoot = Split-Path -Parent $ProfileD
                $fallbackFragmentLibDir = Join-Path $repoRoot 'scripts' 'lib' 'fragment'
                $fallbackOrchestrationModulePath = Join-Path $fallbackFragmentLibDir 'FragmentCommandParserOrchestration.psm1'
                if (Test-Path -LiteralPath $fallbackOrchestrationModulePath) {
                    $orchestrationModulePath = $fallbackOrchestrationModulePath
                    $FragmentLibDir = $fallbackFragmentLibDir
                }
            }
        }
            
        if (Test-Path -LiteralPath $orchestrationModulePath) {
            if (-not (Get-Command Register-AllFragmentCommands -ErrorAction SilentlyContinue)) {
                # Temporarily suppress PowerShell's Import-Module verbose messages
                $oldVerbosePreference = $VerbosePreference
                $VerbosePreference = 'SilentlyContinue'
                Import-Module $orchestrationModulePath -DisableNameChecking -ErrorAction SilentlyContinue -Force
                $VerbosePreference = $oldVerbosePreference
            }
        }
            
        # Pre-register commands from all fragments
        if (Get-Command Register-AllFragmentCommands -ErrorAction SilentlyContinue) {
            try {
                # Diagnostic: Show that pre-registration is starting (if debug enabled)
                $debugLevel = 0
                $hasDebug = $env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel)
                if ($hasDebug -and $debugLevel -ge 2) {
                    Write-Host "[profile-fragment-loader.pre-register] Starting command pre-registration for $($FragmentsToLoad.Count) fragments..." -ForegroundColor Cyan
                }
                
                $preRegisterStart = Get-Date
                # Always use both AST and regex parsing for complete command discovery
                $preRegisterStats = Register-AllFragmentCommands -FragmentFiles $FragmentsToLoad.ToArray() -ForceBothParsingModes
                $preRegisterTime = (Get-Date) - $preRegisterStart
                    
                # Show results if debug enabled or commands registered
                $debugLevel = 0
                $hasDebug = $env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel)
                if ($hasDebug -and $debugLevel -ge 1) {
                    Write-Host ""
                    # Use Green if successful, Yellow if warnings, Red if errors
                    $summaryColor = if ($preRegisterStats.FailedFragments -gt 0) { 'Red' } 
                    elseif ($preRegisterStats.RegisteredCommands -eq 0) { 'Yellow' } 
                    else { 'Green' }
                    Write-Host "[profile-fragment-loader.pre-register] Command pre-registration completed" -ForegroundColor $summaryColor
                    $statusColor = if ($preRegisterStats.FailedFragments -gt 0) { 'Red' } 
                    elseif ($preRegisterStats.RegisteredCommands -eq 0) { 'Yellow' } 
                    else { 'Green' }
                    Write-Host "  [profile-fragment-loader.pre-register] Fragments: $($preRegisterStats.TotalFragments), Commands: $($preRegisterStats.RegisteredCommands), Failed: $($preRegisterStats.FailedFragments), Time: $([int][Math]::Round($preRegisterTime.TotalMilliseconds))ms" -ForegroundColor $statusColor
                    if ($debugLevel -ge 2) {
                        $preRegRows = @(
                            [pscustomobject]@{
                                Fragments          = $preRegisterStats.TotalFragments
                                RegisteredCommands = $preRegisterStats.RegisteredCommands
                                FailedFragments    = $preRegisterStats.FailedFragments
                                ParsedFragments    = if ($preRegisterStats.ParsedFragments) { $preRegisterStats.ParsedFragments } else { $null }
                                CachedFragments    = if ($preRegisterStats.CachedFragments) { $preRegisterStats.CachedFragments } else { $null }
                                TimeMs             = [int][Math]::Round($preRegisterTime.TotalMilliseconds)
                            }
                        )
                        $table = $preRegRows | Format-Table -AutoSize | Out-String
                        Write-Host ($table.TrimEnd()) -ForegroundColor DarkGray
                    }
                    Write-Host ""
                }
            }
            catch {
                # Pre-registration failed, but don't block fragment loading
                if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                    Write-StructuredError -ErrorRecord $_ -OperationName 'fragment-registry.pre-register-all' -Context @{
                        total_fragments = $FragmentsToLoad.Count
                    }
                }
            }
        }
    }

    # Delegate to lazy loading module if available
    $lazyLoadingModule = Get-Module ProfileFragmentLazyLoading -ErrorAction SilentlyContinue
    $lazyLoadingModulePath = Join-Path $PSScriptRoot 'ProfileFragmentLazyLoading.psm1'
    
    if (-not $lazyLoadingModule) {
        # Try to import lazy loading module
        if (Test-Path -LiteralPath $lazyLoadingModulePath) {
            Import-Module $lazyLoadingModulePath -DisableNameChecking -ErrorAction SilentlyContinue -Force
            $lazyLoadingModule = Get-Module ProfileFragmentLazyLoading -ErrorAction SilentlyContinue
        }
    }
    
    $shouldReturnEarly = $false
    
    if ($lazyLoadingModule) {
        $handleCmd = Get-Command -Module ProfileFragmentLazyLoading Handle-LazyLoadingMode -ErrorAction SilentlyContinue
        if ($handleCmd) {
            # Call lazy loading handler function
            # Ensure DisabledSet is not null (use empty HashSet if null)
            $disabledSetParam = if ($null -eq $DisabledSet) {
                [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
            }
            else {
                $DisabledSet
            }
            $shouldReturnEarly = & $handleCmd -LazyLoadEnabled $lazyLoadEnabled -FragmentsToLoad $FragmentsToLoad -DisabledSet $disabledSetParam
        }
    }
    
    # Fallback: If lazy loading module is not available, use inline implementation
    if (-not $lazyLoadingModule -or -not (Get-Command -Module ProfileFragmentLazyLoading Handle-LazyLoadingMode -ErrorAction SilentlyContinue)) {
        # If lazy loading is enabled, skip fragment loading (commands will load on-demand)
        if ($lazyLoadEnabled) {
            $debugLevel = 0
            $hasDebug = $env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel)
            
            # Count available fragments
            $availableCount = 0
            foreach ($frag in $FragmentsToLoad) {
                if ($frag.BaseName -and (-not $DisabledSet -or -not $DisabledSet.Contains($frag.BaseName))) {
                    $availableCount++
                }
            }
            
            # Build fragment names list once if needed for debug output (Level 2+)
            $fragmentNames = $null
            if ($hasDebug -and $debugLevel -ge 2) {
                $fragmentNames = @()
                foreach ($frag in $FragmentsToLoad) {
                    if ($frag.BaseName -and (-not $DisabledSet -or -not $DisabledSet.Contains($frag.BaseName))) {
                        $fragmentNames += $frag.BaseName
                    }
                }
            }
            
            # Debug level 0: No output (silent)
            # Debug level 1: Basic summary message
            if ($hasDebug -and $debugLevel -ge 1) {
                Write-Host ""
                Write-Host "[profile-fragment-loader.lazy-load] Lazy loading enabled - fragments will load on-demand" -ForegroundColor Cyan
                Write-Host "  [profile-fragment-loader.lazy-load] $availableCount fragments available for on-demand loading" -ForegroundColor Green
                Write-Host "  [profile-fragment-loader.lazy-load] Pre-registered commands are available in the registry" -ForegroundColor Green
            }
            
            # Debug level 2: Compact fragment list sample (first 10)
            if ($hasDebug -and $debugLevel -ge 2 -and $fragmentNames) {
                $sampleSize = [Math]::Min(10, $fragmentNames.Count)
                $sample = $fragmentNames[0..($sampleSize - 1)]
                $sampleList = $sample -join ', '
                
                if ($fragmentNames.Count -le 10) {
                    Write-Host "  [profile-fragment-loader] Available fragments: $sampleList" -ForegroundColor DarkGray
                }
                else {
                    Write-Host "  [profile-fragment-loader] Available fragments ($availableCount total): $sampleList, ..." -ForegroundColor DarkGray
                }
            }
            
            # Debug level 3: Full fragment listing (for detailed diagnostics) - compact multi-line format
            if ($hasDebug -and $debugLevel -ge 3 -and $fragmentNames) {
                Write-Host "  [profile-fragment-loader] Full fragment list ($availableCount fragments):" -ForegroundColor DarkGray
                # Display in compact format: multiple fragments per line
                $itemsPerLine = 5
                for ($i = 0; $i -lt $fragmentNames.Count; $i += $itemsPerLine) {
                    $lineItems = $fragmentNames[$i..([Math]::Min($i + $itemsPerLine - 1, $fragmentNames.Count - 1))]
                    $line = "    " + ($lineItems -join ', ')
                    Write-Host $line -ForegroundColor DarkGray
                }
            }
            
            if ($hasDebug -and $debugLevel -ge 1) {
                Write-Host ""
            }
            
            $shouldReturnEarly = $true
        }
    }
    
    # Return early if lazy loading is enabled (fragments will load on-demand via CommandDispatcher)
    if ($shouldReturnEarly) {
        return
    }

    # Delegate to dependency parsing module if available
    $dependencyParsingModule = Get-Module ProfileFragmentDependencyParsing -ErrorAction SilentlyContinue
    $dependencyParsingModulePath = Join-Path $PSScriptRoot 'ProfileFragmentDependencyParsing.psm1'
    
    if (-not $dependencyParsingModule) {
        # Try to import dependency parsing module
        if (Test-Path -LiteralPath $dependencyParsingModulePath) {
            Import-Module $dependencyParsingModulePath -DisableNameChecking -ErrorAction SilentlyContinue -Force
            $dependencyParsingModule = Get-Module ProfileFragmentDependencyParsing -ErrorAction SilentlyContinue
        }
    }
    
    $fragmentLevels = $null
    $useParallelLoading = $false
    $parallelLoadingModuleLoaded = $false
    
    if ($dependencyParsingModule -and $EnableParallelLoading -and $FragmentLoadingModuleExists) {
        $parseCmd = Get-Command -Module ProfileFragmentDependencyParsing Parse-FragmentDependencies -ErrorAction SilentlyContinue
        if ($parseCmd) {
            # Call dependency parsing function
            # Ensure DisabledSet is not null (use empty HashSet if null)
            $disabledSetParam = if ($null -eq $DisabledSet) {
                [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
            }
            else {
                $DisabledSet
            }
            $parseResult = & $parseCmd -FragmentsToLoad $FragmentsToLoad -DisabledFragments $DisabledFragments -EnableParallelLoading $EnableParallelLoading -FragmentLoadingModule $FragmentLoadingModule -FragmentLibDir $FragmentLibDir -DisabledSet $disabledSetParam -BootstrapNameSet $bootstrapNameSet
            
            if ($parseResult) {
                $fragmentLevels = $parseResult.FragmentLevels
                $dependencyParsingTimeMs = $parseResult.DependencyParsingTimeMs
                $dependencyLevelsCount = $parseResult.DependencyLevelsCount
                $useParallelLoading = $parseResult.UseParallelLoading
                $parallelLoadingModuleLoaded = $parseResult.ParallelLoadingModuleLoaded
            }
        }
    }
    
    # Fallback: If dependency parsing module is not available, use inline implementation
    if (-not $dependencyParsingModule -or -not (Get-Command -Module ProfileFragmentDependencyParsing Parse-FragmentDependencies -ErrorAction SilentlyContinue)) {
        if ($EnableParallelLoading -and $FragmentLoadingModuleExists) {
            if (-not (Get-Command Get-FragmentDependencyLevels -ErrorAction SilentlyContinue)) {
                Import-Module $FragmentLoadingModule -ErrorAction SilentlyContinue -DisableNameChecking -Force
            }

            if (Get-Command Get-FragmentDependencyLevels -ErrorAction SilentlyContinue) {
                try {
                    $groupingStart = Get-Date
                    $debugLevel = 0
                    $hasDebug = $env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel)
                    if ($hasDebug) {
                        $env:PS_PROFILE_DEBUG_SUPPRESS_DEPENDENCY_OUTPUT = '1'
                    }

                    $fragmentLevels = Get-FragmentDependencyLevels -FragmentFiles $FragmentsToLoad.ToArray() -DisabledFragments $DisabledFragments

                    if ($hasDebug) {
                        $env:PS_PROFILE_DEBUG_SUPPRESS_DEPENDENCY_OUTPUT = $null
                    }

                    $groupingTime = (Get-Date) - $groupingStart
                    $dependencyParsingTimeMs = [int][Math]::Round($groupingTime.TotalMilliseconds)
                    $dependencyLevelsCount = if ($fragmentLevels -and $fragmentLevels.Keys) { $fragmentLevels.Keys.Count } else { 0 }

                    # Decide whether parallel loading provides value
                    $levelsWithMultipleFragments = 0
                    foreach ($levelKey in $fragmentLevels.Keys) {
                        $enabledCount = 0
                        foreach ($frag in $fragmentLevels[$levelKey]) {
                            $bn = $frag.BaseName
                            if ($bootstrapNameSet.Contains($bn)) { continue }
                            if ($bn -eq 'bootstrap' -or (-not $DisabledSet -or -not $DisabledSet.Contains($bn))) {
                                $enabledCount++
                            }
                        }
                        if ($enabledCount -gt 1) { $levelsWithMultipleFragments++ }
                    }
                    $useParallelLoading = $levelsWithMultipleFragments -gt 0

                    if ($useParallelLoading) {
                        $parallelLoadingModulePath = Join-Path $FragmentLibDir 'FragmentParallelLoading.psm1'
                        if (Test-Path -LiteralPath $parallelLoadingModulePath) {
                            Import-Module $parallelLoadingModulePath -ErrorAction SilentlyContinue -DisableNameChecking
                            $parallelLoadingModuleLoaded = [bool](Get-Command Invoke-FragmentsInParallel -ErrorAction SilentlyContinue)
                        }

                        if (-not $parallelLoadingModuleLoaded) {
                            $useParallelLoading = $false
                        }
                    }

                    $debugLevel = 0
                    if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel) -and $debugLevel -ge 2) {
                        Write-Host ""
                        Write-Host "[profile-fragment-loader.dependency] Dependency analysis for $($FragmentsToLoad.Count) fragments" -ForegroundColor Cyan
                        $depRows = @(
                            [pscustomobject]@{
                                Fragments   = $FragmentsToLoad.Count
                                Levels      = $dependencyLevelsCount
                                UseParallel = $useParallelLoading
                                TimeMs      = $dependencyParsingTimeMs
                            }
                        )
                        $table = $depRows | Format-Table -AutoSize | Out-String
                        Write-Host ($table.TrimEnd()) -ForegroundColor DarkGray
                        Write-Host ""
                        $global:PSProfileDependencyAnalysisShown = $true
                    }
                }
                catch {
                    $env:PS_PROFILE_DEBUG_SUPPRESS_DEPENDENCY_OUTPUT = $null
                    if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                        Write-StructuredError -ErrorRecord $_ -OperationName 'profile.fragment.dependency-grouping' -Context @{
                            fragment_count = $FragmentsToLoad.Count
                        }
                    }
                    elseif (Get-Command Write-StructuredWarning -ErrorAction SilentlyContinue) {
                        Write-StructuredWarning -Message "Failed to group fragments by dependency level, using sequential loading" -OperationName 'profile.fragment.dependency-grouping' -Context @{
                            error_message  = $_.Exception.Message
                            fragment_count = $FragmentsToLoad.Count
                        } -Code 'DependencyGroupingFailed'
                    }
                    else {
                        Write-Warning "[profile-fragment-loader.dependency] Failed to group fragments by dependency level: $($_.Exception.Message). Using sequential loading."
                    }
                    $useParallelLoading = $false
                    $fragmentLevels = $null
                }
            }
        }
    }

    # Delegate to orchestration module if available
    $orchestrationModule = Get-Module ProfileFragmentLoadingOrchestration -ErrorAction SilentlyContinue
    $orchestrationModulePath = Join-Path $PSScriptRoot 'ProfileFragmentLoadingOrchestration.psm1'
    
    if (-not $orchestrationModule) {
        # Try to import orchestration module
        if (Test-Path -LiteralPath $orchestrationModulePath) {
            Import-Module $orchestrationModulePath -DisableNameChecking -ErrorAction SilentlyContinue -Force
            $orchestrationModule = Get-Module ProfileFragmentLoadingOrchestration -ErrorAction SilentlyContinue
        }
    }
    
    if ($orchestrationModule) {
        $orchestrationCmd = Get-Command -Module ProfileFragmentLoadingOrchestration Invoke-FragmentLoadingOrchestration -ErrorAction SilentlyContinue
        if ($orchestrationCmd) {
            # Create scriptblocks for progress functions
            $writeHeader = { Write-BatchProgressTableHeader }
            $writeRow = { 
                param(
                    [int]$BatchNumber,
                    [int]$TotalBatches,
                    [int]$FragmentCount,
                    [string[]]$FragmentNames
                )
                Write-BatchProgressRow -BatchNumber $BatchNumber -TotalBatches $TotalBatches -FragmentCount $FragmentCount -FragmentNames $FragmentNames
            }
            
            # Call orchestration function
            # Ensure DisabledSet is not null (use empty HashSet if null)
            $disabledSetParam = if ($null -eq $DisabledSet) {
                [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
            }
            else {
                $DisabledSet
            }
            & $orchestrationCmd `
                -FragmentsToLoad $FragmentsToLoad `
                -DisabledSet $disabledSetParam `
                -BootstrapFragment $BootstrapFragment `
                -BootstrapNameSet $bootstrapNameSet `
                -ProfileD $ProfileD `
                -FragmentErrorHandlingModuleExists $FragmentErrorHandlingModuleExists `
                -UseParallelLoading $useParallelLoading `
                -ParallelLoadingModuleLoaded $parallelLoadingModuleLoaded `
                -FragmentLevels $fragmentLevels `
                -AllSucceeded $allSucceeded `
                -AllFailed $allFailed `
                -FailedNames $failedNames `
                -LoadedFragments $script:LoadedFragments `
                -FragmentLoadingBatchSize $script:FragmentLoadingBatchSize `
                -WriteBatchProgressTableHeader $writeHeader `
                -WriteBatchProgressRow $writeRow
            return
        }
    }
    
    # Fallback: If orchestration module is not available, use inline implementation
    # This maintains backward compatibility but should not normally be needed
    if (Get-Command Write-StructuredWarning -ErrorAction SilentlyContinue) {
        Write-StructuredWarning -Message "ProfileFragmentLoadingOrchestration module not available, using fallback implementation" -OperationName 'profile-fragment-loader.orchestration' -Context @{
            orchestration_module_path = $orchestrationModulePath
        } -Code 'OrchestrationModuleUnavailable'
    }
    
    # Fallback implementation (simplified sequential loading only)
    foreach ($frag in $FragmentsToLoad) {
        if ($frag.BaseName -and $DisabledSet -and $DisabledSet.Contains($frag.BaseName)) {
            continue
        }
        
        try {
            $null = . $frag.FullName
            [void]$allSucceeded.Add($frag.BaseName)
        }
        catch {
            if (-not $failedNames.Contains($frag.BaseName)) {
                $allFailed.Add(@{ Name = $frag.BaseName; Error = $_.Exception.Message })
                [void]$failedNames.Add($frag.BaseName)
            }
        }
    }

    # Delegate to proxy creation module if available
    $proxyCreationModule = Get-Module ProfileFragmentProxyCreation -ErrorAction SilentlyContinue
    $proxyCreationModulePath = Join-Path $PSScriptRoot 'ProfileFragmentProxyCreation.psm1'
    
    if (-not $proxyCreationModule) {
        # Try to import proxy creation module
        if (Test-Path -LiteralPath $proxyCreationModulePath) {
            Import-Module $proxyCreationModulePath -DisableNameChecking -ErrorAction SilentlyContinue -Force
            $proxyCreationModule = Get-Module ProfileFragmentProxyCreation -ErrorAction SilentlyContinue
        }
    }
    
    if ($proxyCreationModule) {
        $proxyCmd = Get-Command -Module ProfileFragmentProxyCreation Create-FragmentCommandProxies -ErrorAction SilentlyContinue
        if ($proxyCmd) {
            # Call proxy creation function
            $null = & $proxyCmd -LazyLoadEnabled $lazyLoadEnabled -PreRegisterEnabled $preRegisterEnabled -FragmentsToLoad $FragmentsToLoad -FragmentLibDir $FragmentLibDir -ProfileD $ProfileD
        }
    }
    
    # Fallback: If proxy creation module is not available, use inline implementation
    if (-not $proxyCreationModule -or -not (Get-Command -Module ProfileFragmentProxyCreation Create-FragmentCommandProxies -ErrorAction SilentlyContinue)) {
        # Create proxy functions for autocomplete (deferred until after bootstrap is fully loaded)
        # This makes commands available for tab completion even though fragments aren't loaded
        # Only create proxies if lazy loading is enabled and proxy creation is enabled
        if ($lazyLoadEnabled -and $preRegisterEnabled) {
            # Check if proxy creation is enabled (default: enabled)
            $createProxiesEnabled = $true
            if ($env:PS_PROFILE_CREATE_PROXIES) {
                $normalized = $env:PS_PROFILE_CREATE_PROXIES.Trim().ToLowerInvariant()
                $createProxiesEnabled = ($normalized -eq '1' -or $normalized -eq 'true')
            }
            
            if ($createProxiesEnabled) {
                if ($env:PS_PROFILE_DEBUG) {
                    Write-Host "Creating proxy functions for autocomplete (after bootstrap load)..." -ForegroundColor DarkGray
                }
                
                # Ensure Create-CommandProxiesForAutocomplete is available
                if (-not (Get-Command Create-CommandProxiesForAutocomplete -ErrorAction SilentlyContinue)) {
                    # Try to import FragmentCommandRegistry module if not already loaded
                    $registryModulePath = Join-Path $FragmentLibDir 'FragmentCommandRegistry.psm1'
                    
                    # Fallback: if path doesn't exist, try to resolve from ProfileD
                    if (-not (Test-Path -LiteralPath $registryModulePath)) {
                        if ($ProfileD -and (Test-Path -LiteralPath $ProfileD)) {
                            $repoRoot = Split-Path -Parent $ProfileD
                            $fallbackFragmentLibDir = Join-Path $repoRoot 'scripts' 'lib' 'fragment'
                            $fallbackRegistryModulePath = Join-Path $fallbackFragmentLibDir 'FragmentCommandRegistry.psm1'
                            if (Test-Path -LiteralPath $fallbackRegistryModulePath) {
                                $registryModulePath = $fallbackRegistryModulePath
                                $FragmentLibDir = $fallbackFragmentLibDir
                            }
                        }
                    }
                    
                    if (Test-Path -LiteralPath $registryModulePath) {
                        Import-Module $registryModulePath -DisableNameChecking -ErrorAction SilentlyContinue -Force
                    }
                }
                
                if (Get-Command Create-CommandProxiesForAutocomplete -ErrorAction SilentlyContinue) {
                    try {
                        $proxyStart = Get-Date
                        $proxyStats = Create-CommandProxiesForAutocomplete -FragmentFiles $FragmentsToLoad.ToArray()
                        $proxyTime = (Get-Date) - $proxyStart
                        
                        $debugLevel = 0
                        if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel) -and $debugLevel -ge 2) {
                            Write-Host ""
                            Write-Host "[profile-fragment-loader.proxy] Command proxy creation summary" -ForegroundColor Cyan
                            $proxyRows = @(
                                [pscustomobject]@{
                                    TotalCommands  = $proxyStats.TotalCommands
                                    CreatedProxies = $proxyStats.CreatedProxies
                                    FailedProxies  = $proxyStats.FailedProxies
                                    TimeMs         = [int][Math]::Round($proxyTime.TotalMilliseconds)
                                }
                            )
                            $table = $proxyRows | Format-Table -AutoSize | Out-String
                            Write-Host ($table.TrimEnd()) -ForegroundColor DarkGray
                            Write-Host ""
                        }
                        elseif ($proxyStats.CreatedProxies -gt 0) {
                            if ($debugLevel -ge 2) {
                                Write-Host "  [profile-fragment-loader] Created $($proxyStats.CreatedProxies) proxy functions for autocomplete" -ForegroundColor DarkGray
                            }
                        }
                    }
                    catch {
                        # Proxy creation failed, but don't block loading
                        if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                            Write-StructuredError -ErrorRecord $_ -OperationName 'fragment-registry.create-proxies' -Context @{
                                fragment_count = $FragmentsToLoad.Count
                            }
                        }
                        elseif (Get-Command Write-StructuredWarning -ErrorAction SilentlyContinue) {
                            Write-StructuredWarning -Message "Failed to create command proxies for autocomplete" -OperationName 'fragment-registry.create-proxies' -Context @{
                                error_message  = $_.Exception.Message
                                fragment_count = $FragmentsToLoad.Count
                            } -Code 'ProxyCreationFailed'
                        }
                        elseif ($env:PS_PROFILE_DEBUG) {
                            Write-Host "Proxy creation failed (autocomplete may not work): $($_.Exception.Message)" -ForegroundColor Yellow
                            if ($_.ScriptStackTrace) {
                                Write-Host "Stack trace: $($_.ScriptStackTrace)" -ForegroundColor DarkGray
                            }
                        }
                    }
                }
                else {
                    if (Get-Command Write-StructuredWarning -ErrorAction SilentlyContinue) {
                        Write-StructuredWarning -Message "Create-CommandProxiesForAutocomplete not available - autocomplete may not work" -OperationName 'fragment-registry.create-proxies' -Context @{
                            registry_module_path         = $registryModulePath
                            module_exists                = (Test-Path -LiteralPath $registryModulePath)
                            new_proxy_function_available = (Get-Command New-FragmentCommandProxy -ErrorAction SilentlyContinue -ne $null)
                        } -Code 'ProxyFunctionNotAvailable'
                    }
                    elseif ($env:PS_PROFILE_DEBUG) {
                        Write-Host "Create-CommandProxiesForAutocomplete not available - autocomplete may not work" -ForegroundColor Yellow
                        Write-Host "  - Registry module path: $registryModulePath" -ForegroundColor DarkGray
                        Write-Host "  - Module exists: $(Test-Path -LiteralPath $registryModulePath)" -ForegroundColor DarkGray
                        Write-Host "  - New-FragmentCommandProxy available: $(Get-Command New-FragmentCommandProxy -ErrorAction SilentlyContinue -ne $null)" -ForegroundColor DarkGray
                    }
                }
            }
            elseif ($env:PS_PROFILE_DEBUG) {
                Write-Host "Proxy creation disabled (PS_PROFILE_CREATE_PROXIES=0) - autocomplete may not work" -ForegroundColor DarkGray
            }
        }
    }

    if (Get-Command Record-FragmentResults -ErrorAction SilentlyContinue) {
        $succeededArray = @($allSucceeded)
        $failedArray = @($allFailed)
        Record-FragmentResults -SucceededFragments $succeededArray -FailedFragments $failedArray
    }

    if ($null -ne $dependencyParsingTimeMs -and (Get-Command Record-DependencyParsing -ErrorAction SilentlyContinue)) {
        Record-DependencyParsing -ParsingTime $dependencyParsingTimeMs -DependencyLevels $dependencyLevelsCount
    }
        
    # Show remaining fragments if we're batching
    # Level 1: Batched output, Level 2+: Individual messages (already shown)
    $debugLevel = 0
    if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel) -and $debugLevel -ge 1) {
        # Only show batched output at Level 1 (Level 2+ shows individual messages)
        if ($debugLevel -eq 1) {
            $remainingCount = $script:LoadedFragments.Count % $script:FragmentLoadingBatchSize
            if ($remainingCount -gt 0) {
                $batchStart = $script:LoadedFragments.Count - $remainingCount
                $batch = $script:LoadedFragments[$batchStart..($script:LoadedFragments.Count - 1)]
                $fragmentList = ($batch -join ', ')
                Write-Host "Loading fragments ($($script:LoadedFragments.Count) total): $fragmentList" -ForegroundColor Cyan
            }
                
            # Show summary
            if ($script:LoadedFragments.Count -gt 0) {
                Write-Host ""
                Write-Host "Loaded $($script:LoadedFragments.Count) fragments successfully" -ForegroundColor Green
            }
        }
    }
}

Export-ModuleMember -Function Initialize-FragmentLoading
