# ===============================================
# ProfileFragmentConfig.psm1
# Fragment configuration loading and setup
# ===============================================

<#
.SYNOPSIS
    Loads and initializes fragment configuration.
.DESCRIPTION
    Loads fragment configuration from FragmentConfig module, including disabled fragments,
    load order overrides, environment sets, feature flags, and performance configuration.
.PARAMETER ProfileDir
    Directory containing the profile files.
.PARAMETER FragmentConfigModule
    Path to the FragmentConfig module.
.OUTPUTS
    Hashtable with keys: DisabledFragments, LoadOrderOverride, EnvironmentSets, FeatureFlags, PerformanceConfig, AllFragments, ProfileDExists
#>
function Initialize-FragmentConfiguration {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$ProfileDir,
        
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$FragmentConfigModule
    )

    # Initialize fragment configuration (disabled fragments, load order, environment sets, feature flags)
    $disabledFragments = @()
    $loadOrderOverride = @()
    $environmentSets = @{}
    $featureFlags = @{}
    $performanceConfig = @{ 
        maxFragmentTime           = 500
        parallelDependencyParsing = $true  # Enable parallel dependency parsing for faster startup
    }

    # Cache Test-Path result for fragment config module
    $fragmentConfigModuleExists = if ($FragmentConfigModule -and -not [string]::IsNullOrWhiteSpace($FragmentConfigModule)) { 
        Test-Path -LiteralPath $FragmentConfigModule 
    } 
    else { 
        $false 
    }
    
    $debugLevel = 0
    if ($fragmentConfigModuleExists) {
        # Level 2: Log config module loading
        if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel) -and $debugLevel -ge 2) {
            Write-Verbose "[profile-fragment-config.init] Loading fragment configuration module: $FragmentConfigModule"
        }
        try {
            Import-Module $FragmentConfigModule -ErrorAction Stop -DisableNameChecking
            # Verify the function is available after import
            if (-not (Get-Command Get-FragmentConfig -ErrorAction SilentlyContinue)) {
                throw "Get-FragmentConfig function not found after importing FragmentConfig module"
            }
            $config = Get-FragmentConfig -ProfileDir $ProfileDir
            $disabledFragments = $config.DisabledFragments
            $loadOrderOverride = $config.LoadOrder
            $environmentSets = $config.Environments
            $featureFlags = $config.FeatureFlags
            $performanceConfig = $config.Performance
            # Level 2: Log successful config load
            if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel) -and $debugLevel -ge 2) {
                Write-Verbose "[profile-fragment-config.init] Successfully loaded fragment configuration"
            }
            # Level 3: Log detailed configuration
            if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel) -and $debugLevel -ge 3) {
                Write-Host "  [profile-fragment-config.init] Configuration details - DisabledFragments: $($disabledFragments.Count), LoadOrder: $($loadOrderOverride.Count), Environments: $($environmentSets.Keys.Count), FeatureFlags: $($featureFlags.Keys.Count)" -ForegroundColor DarkGray
            }
        }
        catch {
            $debugLevel = 0
            if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel)) {
                if ($debugLevel -ge 1) {
                    if (Get-Command Write-StructuredWarning -ErrorAction SilentlyContinue) {
                        Write-StructuredWarning -Message "Failed to load fragment config module: $($_.Exception.Message)" -OperationName 'profile-fragment-config.init' -Context @{
                            # Technical context
                            ProfileDir           = $ProfileDir
                            FragmentConfigModule = $FragmentConfigModule
                            # Error context
                            Error                = $_.Exception.Message
                            ErrorType            = $_.Exception.GetType().FullName
                            # Invocation context
                            FunctionName         = 'Initialize-FragmentConfiguration'
                        }
                    }
                    else {
                        Write-Warning "[profile-fragment-config.init] Failed to load fragment config module: $($_.Exception.Message)"
                    }
                }
                # Level 3: Log detailed error information
                if ($debugLevel -ge 3) {
                    Write-Host "  [profile-fragment-config.init] Config module load error details - Exception: $($_.Exception.GetType().FullName), Message: $($_.Exception.Message), ModulePath: $FragmentConfigModule" -ForegroundColor DarkGray
                }
            }
        }
    }

    # Cache profile.d directory existence check
    $profileD = Join-Path $ProfileDir 'profile.d'
    $profileDExists = if ($profileD -and -not [string]::IsNullOrWhiteSpace($profileD)) { 
        Test-Path -LiteralPath $profileD 
    } 
    else { 
        $false 
    }
    
    # Level 3: Log profile.d directory check
    if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel) -and $debugLevel -ge 3) {
        if ($debugLevel -ge 2) {
            Write-Verbose "[profile-fragment-config.init] Profile.d directory check - Path: $profileD, Exists: $profileDExists"
        }
        if ($debugLevel -ge 3) {
            Write-Host "  [profile-fragment-config.init] Profile.d directory check - Path: $profileD, Exists: $profileDExists" -ForegroundColor DarkGray
        }
    }

    # Cache fragment file list to avoid multiple Get-ChildItem calls
    # Exclude test files (files containing "-test-" in the name) that are created temporarily during testing
    $allFragments = $null
    if ($profileDExists) {
        $allFragments = Get-ChildItem -Path $profileD -File -Filter '*.ps1' -ErrorAction SilentlyContinue | 
        Where-Object { 
            # Exclude test files: files containing "-test-" in the name
            # UNLESS we're in test mode (PS_PROFILE_TEST_MODE is set)
            if ($env:PS_PROFILE_TEST_MODE) {
                # In test mode, allow test fragments
                return $true
            }
            $_.BaseName -notmatch '-test-'
        }
        # Level 2: Log fragment discovery
        if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel) -and $debugLevel -ge 2) {
            $fragmentCount = if ($allFragments) { $allFragments.Count } else { 0 }
            Write-Verbose "[profile-fragment-config.init] Discovered $fragmentCount fragment(s) in profile.d directory"
        }
        # Level 3: Log detailed fragment list
        if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel) -and $debugLevel -ge 3) {
            if ($allFragments) {
                $fragmentNames = $allFragments.BaseName -join ', '
                Write-Verbose "[profile-fragment-config.init] Fragment list: $fragmentNames"
            }
        }
    }

    # Helper function to normalize boolean environment variables
    # Supports: '1', 'true' (case-insensitive) -> $true
    #           '0', 'false' (case-insensitive), empty/null -> $false
    function Test-EnvBool {
        param([string]$Value)
        if ([string]::IsNullOrWhiteSpace($Value)) {
            return $false
        }
        $normalized = $Value.Trim().ToLowerInvariant()
        return ($normalized -eq '1' -or $normalized -eq 'true')
    }

    # Check if we should load all fragments (override disabled fragments and environment restrictions)
    $loadAllFragments = Test-EnvBool -Value $env:PS_PROFILE_LOAD_ALL

    # Apply environment-specific fragment sets (if PS_PROFILE_ENVIRONMENT is set)
    # Environment sets allow loading only specific fragments (useful for CI/CD or minimal profiles)
    # NOTE: PS_PROFILE_LOAD_ALL=1 overrides environment restrictions
    # NOTE: "full" environment automatically loads all fragments (no list needed)
    $currentEnvironment = $env:PS_PROFILE_ENVIRONMENT
    if (-not $loadAllFragments -and $currentEnvironment -and $currentEnvironment -ne 'full' -and $environmentSets.ContainsKey($currentEnvironment) -and $allFragments) {
        $enabledFragments = $environmentSets[$currentEnvironment]
        # Optimized: Use HashSet for O(1) lookups instead of array membership checks
        $enabledSet = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
        foreach ($name in $enabledFragments) {
            [void]$enabledSet.Add($name)
        }

        # Disable all fragments except those in the environment set (bootstrap always loads)
        # Build enabled set for O(1) lookups
        $enabledSet = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
        foreach ($enabledName in $enabledFragments) {
            [void]$enabledSet.Add($enabledName)
        }
        
        # Single-pass filtering: build disabled fragments list
        $disabledFragments = [System.Collections.Generic.List[string]]::new()
        foreach ($fragment in $allFragments) {
            $baseName = $fragment.BaseName
            if ($baseName -eq 'bootstrap') {
                continue
            }
            
            # Check if fragment is enabled using O(1) HashSet lookup
            if (-not $enabledSet.Contains($baseName)) {
                $disabledFragments.Add($baseName)
            }
        }

        $debugLevel = 0
        if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel)) {
            # Level 1: Basic environment info
            if ($debugLevel -ge 1) {
                Write-Verbose "[profile-fragment-config.environment] Environment '$currentEnvironment' active. Enabled fragments: $($enabledFragments -join ', ')"
            }
            # Level 2: Log environment configuration summary
            if ($debugLevel -ge 2) {
                Write-Verbose "[profile-fragment-config.environment] Environment configuration - Name: $currentEnvironment, Enabled: $($enabledFragments.Count), Disabled: $($disabledFragments.Count)"
            }
            # Level 3: Log detailed environment filtering
            if ($debugLevel -ge 3) {
                Write-Host "  [profile-fragment-config.environment] Environment filtering details - Enabled fragments: $($enabledFragments -join ', '), Disabled fragments: $($disabledFragments -join ', ')" -ForegroundColor DarkGray
            }
        }
        else {
            # Even without debug, show a brief message to indicate we're starting fragment loading
            Write-Host "Loading profile fragments..." -ForegroundColor Gray -NoNewline
        }
    }

    # Override disabled fragments if PS_PROFILE_LOAD_ALL is set
    if ($loadAllFragments) {
        $debugLevel = 0
        if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel)) {
            # Level 1: Basic load all override info
            if ($debugLevel -ge 1) {
                Write-Verbose "[profile-fragment-config.load-all] PS_PROFILE_LOAD_ALL enabled: Loading all fragments (overriding disabled fragments and environment restrictions)"
            }
            # Level 2: Log load all override
            if ($debugLevel -ge 2) {
                Write-Verbose "[profile-fragment-config.load-all] Load all override active - All fragments will be loaded"
            }
            # Level 3: Log detailed override information
            if ($debugLevel -ge 3) {
                $originalDisabledCount = $disabledFragments.Count
                Write-Host "  [profile-fragment-config.load-all] Override details - Original disabled count: $originalDisabledCount, All fragments: $($allFragments.Count)" -ForegroundColor DarkGray
            }
        }
        # Clear disabled fragments to load everything
        $disabledFragments = @()
    }
    
    # Level 2: Log final configuration summary
    $debugLevel = 0
    if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel) -and $debugLevel -ge 2) {
        $totalFragments = if ($allFragments) { $allFragments.Count } else { 0 }
        $enabledCount = $totalFragments - $disabledFragments.Count
        Write-Verbose "[profile-fragment-config.init] Final configuration - Total: $totalFragments, Enabled: $enabledCount, Disabled: $($disabledFragments.Count)"
    }

    $scriptsLibDir = Join-Path $ProfileDir 'scripts' 'lib'
    $fragmentLibDir = Join-Path $scriptsLibDir 'fragment'
    $fragmentLoadingModule = Join-Path $fragmentLibDir 'FragmentLoading.psm1'

    return @{
        DisabledFragments     = $disabledFragments
        LoadOrderOverride     = $loadOrderOverride
        EnvironmentSets       = $environmentSets
        FeatureFlags          = $featureFlags
        PerformanceConfig     = $performanceConfig
        AllFragments          = $allFragments
        ProfileDExists        = $profileDExists
        ProfileD              = $profileD
        FragmentLoadingModule = $fragmentLoadingModule
        FragmentLibDir        = $fragmentLibDir
    }
}

<#
.SYNOPSIS
    Normalizes boolean environment variables.
.DESCRIPTION
    Supports: '1', 'true' (case-insensitive) -> $true
              '0', 'false' (case-insensitive), empty/null -> $false
.PARAMETER Value
    The value to normalize.
#>
function Test-EnvBool {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [AllowEmptyString()]
        [AllowNull()]
        [string]$Value
    )
    if ([string]::IsNullOrWhiteSpace($Value)) {
        return $false
    }
    $normalized = $Value.Trim().ToLowerInvariant()
    return ($normalized -eq '1' -or $normalized -eq 'true')
}

Export-ModuleMember -Function 'Initialize-FragmentConfiguration', 'Test-EnvBool'
