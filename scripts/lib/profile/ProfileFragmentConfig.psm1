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
        [string]$ProfileDir,
        
        [Parameter(Mandatory)]
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
    
    if ($fragmentConfigModuleExists) {
        try {
            Import-Module $FragmentConfigModule -ErrorAction SilentlyContinue -DisableNameChecking
            $config = Get-FragmentConfig -ProfileDir $ProfileDir
            $disabledFragments = $config.DisabledFragments
            $loadOrderOverride = $config.LoadOrder
            $environmentSets = $config.Environments
            $featureFlags = $config.FeatureFlags
            $performanceConfig = $config.Performance
        }
        catch {
            if ($env:PS_PROFILE_DEBUG) {
                Write-Host "Warning: Failed to load fragment config module: $($_.Exception.Message)" -ForegroundColor Yellow
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

        if ($env:PS_PROFILE_DEBUG) {
            Write-Host "Environment '$currentEnvironment' active. Enabled fragments: $($enabledFragments -join ', ')" -ForegroundColor Cyan
        }
        else {
            # Even without debug, show a brief message to indicate we're starting fragment loading
            Write-Host "Loading profile fragments..." -ForegroundColor Gray -NoNewline
        }
    }

    # Override disabled fragments if PS_PROFILE_LOAD_ALL is set
    if ($loadAllFragments) {
        if ($env:PS_PROFILE_DEBUG) {
            Write-Host "PS_PROFILE_LOAD_ALL enabled: Loading all fragments (overriding disabled fragments and environment restrictions)" -ForegroundColor Yellow
        }
        # Clear disabled fragments to load everything
        $disabledFragments = @()
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
        [Parameter(Mandatory)]
        [string]$Value
    )
    if ([string]::IsNullOrWhiteSpace($Value)) {
        return $false
    }
    $normalized = $Value.Trim().ToLowerInvariant()
    return ($normalized -eq '1' -or $normalized -eq 'true')
}

Export-ModuleMember -Function 'Initialize-FragmentConfiguration', 'Test-EnvBool'
