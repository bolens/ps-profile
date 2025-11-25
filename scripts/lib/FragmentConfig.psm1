<#
scripts/lib/FragmentConfig.psm1

.SYNOPSIS
    Fragment configuration management utilities.

.DESCRIPTION
    Provides functions for loading, parsing, and managing profile fragment configuration
    from .profile-fragments.json file. Handles disabled fragments, load order overrides,
    environment sets, feature flags, and performance configuration.

.NOTES
    Module Version: 1.0.0
    PowerShell Version: 3.0+
#>

# Import JsonUtilities for JSON operations
$jsonModulePath = Join-Path $PSScriptRoot 'JsonUtilities.psm1'
if (Test-Path $jsonModulePath) {
    try {
        Import-Module $jsonModulePath -ErrorAction Stop
    }
    catch {
        Write-Verbose "Failed to import JsonUtilities module: $($_.Exception.Message). JSON operations may be limited."
    }
}

# Import PathResolution for path operations
$pathModulePath = Join-Path $PSScriptRoot 'PathResolution.psm1'
if (Test-Path $pathModulePath) {
    try {
        Import-Module $pathModulePath -ErrorAction Stop
    }
    catch {
        Write-Verbose "Failed to import PathResolution module: $($_.Exception.Message). Path resolution features may be limited."
    }
}

# Import Logging for consistent output
$loggingModulePath = Join-Path $PSScriptRoot 'Logging.psm1'
if (Test-Path $loggingModulePath) {
    try {
        Import-Module $loggingModulePath -ErrorAction Stop
    }
    catch {
        Write-Verbose "Failed to import Logging module: $($_.Exception.Message). Logging features may be limited."
    }
}

<#
.SYNOPSIS
    Loads and parses the fragment configuration file.

.DESCRIPTION
    Reads the .profile-fragments.json file from the repository root and parses it
    into a structured configuration object. Returns a hashtable with all configuration
    sections.

.PARAMETER ProfileDir
    Optional. Path to the profile directory. If not provided, attempts to resolve
    from the current script context.

.PARAMETER ConfigPath
    Optional. Direct path to the configuration file. If not provided, uses
    .profile-fragments.json in the profile directory.

.OUTPUTS
    System.Collections.Hashtable. Configuration object with keys:
    - DisabledFragments: Array of fragment names to disable
    - LoadOrder: Array of fragment names in load order
    - Environments: Hashtable of environment name -> fragment arrays
    - FeatureFlags: Hashtable of feature flag name -> value
    - Performance: Hashtable with batchLoad and maxFragmentTime

.EXAMPLE
    $config = Get-FragmentConfig
    if ($config.DisabledFragments) {
        Write-Host "Disabled: $($config.DisabledFragments -join ', ')"
    }
#>
function Get-FragmentConfig {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [string]$ProfileDir,
        [string]$ConfigPath
    )

    # Determine config path
    if (-not $ConfigPath) {
        if (-not $ProfileDir) {
            # Try to resolve from current context
            if (Get-Command Get-ProfileDirectory -ErrorAction SilentlyContinue) {
                try {
                    $ProfileDir = Get-ProfileDirectory -ScriptPath $PSScriptRoot
                }
                catch {
                    # Fallback: try to find profile directory relative to common locations
                    $ProfileDir = $null
                }
            }
        }

        if ($ProfileDir) {
            $ConfigPath = Join-Path $ProfileDir '.profile-fragments.json'
        }
        else {
            # Last resort: assume we're in the repo root
            $ConfigPath = Join-Path (Get-Location).Path '.profile-fragments.json'
        }
    }

    # Initialize default configuration
    $config = @{
        DisabledFragments = @()
        LoadOrder         = @()
        Environments      = @{}
        FeatureFlags      = @{}
        Performance       = @{
            batchLoad       = $false
            maxFragmentTime = 500
        }
    }

    # Load configuration file if it exists
    if (-not (Test-Path $ConfigPath)) {
        return $config
    }

    try {
        $configContent = Get-Content -Path $ConfigPath -Raw -ErrorAction Stop
        if ([string]::IsNullOrWhiteSpace($configContent)) {
            return $config
        }

        # Parse JSON with explicit error handling
        try {
            $configObj = $configContent | ConvertFrom-Json -ErrorAction Stop
        }
        catch {
            throw "Invalid JSON in config file: $($_.Exception.Message)"
        }

        # Parse disabled fragments
        if ($configObj.disabled) {
            $config.DisabledFragments = @($configObj.disabled)
        }

        # Parse load order override
        if ($configObj.loadOrder) {
            $config.LoadOrder = @($configObj.loadOrder)
        }

        # Parse environment sets
        if ($configObj.environments) {
            $configObj.environments.PSObject.Properties | ForEach-Object {
                $config.Environments[$_.Name] = @($_.Value)
            }
        }

        # Parse feature flags
        if ($configObj.featureFlags) {
            $configObj.featureFlags.PSObject.Properties | ForEach-Object {
                $config.FeatureFlags[$_.Name] = $_.Value
            }
        }

        # Parse performance configuration
        if ($configObj.performance) {
            if ($configObj.performance.batchLoad) {
                $config.Performance.batchLoad = $configObj.performance.batchLoad
            }
            if ($configObj.performance.maxFragmentTime) {
                $config.Performance.maxFragmentTime = $configObj.performance.maxFragmentTime
            }
        }
    }
    catch {
        $errorMessage = "Failed to load fragment config from '$ConfigPath': $($_.Exception.Message)"
        if ($env:PS_PROFILE_DEBUG) {
            if (Get-Command Write-ScriptMessage -ErrorAction SilentlyContinue) {
                Write-ScriptMessage -Message $errorMessage -IsWarning
            }
            else {
                Write-Host "Warning: $errorMessage" -ForegroundColor Yellow
            }
        }
        # Return default configuration on error
    }

    return $config
}

<#
.SYNOPSIS
    Gets a specific configuration value.

.DESCRIPTION
    Retrieves a specific value from the fragment configuration by key path.
    Supports nested keys using dot notation (e.g., 'Performance.batchLoad').

.PARAMETER Key
    The configuration key to retrieve. Supports dot notation for nested keys.

.PARAMETER DefaultValue
    Optional default value to return if the key is not found.

.PARAMETER ProfileDir
    Optional. Path to the profile directory.

.OUTPUTS
    System.Object. The configuration value, or DefaultValue if not found.

.EXAMPLE
    $batchLoad = Get-FragmentConfigValue -Key 'Performance.batchLoad' -DefaultValue $false
#>
function Get-FragmentConfigValue {
    [CmdletBinding()]
    [OutputType([object])]
    param(
        [Parameter(Mandatory)]
        [string]$Key,

        [object]$DefaultValue = $null,

        [string]$ProfileDir
    )

    $config = Get-FragmentConfig -ProfileDir $ProfileDir

    # Split key by dots for nested access
    $keyParts = $Key -split '\.'
    $current = $config

    foreach ($part in $keyParts) {
        if ($current -is [hashtable] -and $current.ContainsKey($part)) {
            $current = $current[$part]
        }
        elseif ($current -is [PSCustomObject] -and $current.PSObject.Properties[$part]) {
            $current = $current.PSObject.Properties[$part].Value
        }
        else {
            return $DefaultValue
        }
    }

    return $current
}

<#
.SYNOPSIS
    Gets the list of disabled fragments.

.DESCRIPTION
    Returns an array of fragment names that are disabled in the configuration.

.PARAMETER ProfileDir
    Optional. Path to the profile directory.

.OUTPUTS
    System.String[]. Array of disabled fragment names.

.EXAMPLE
    $disabled = Get-DisabledFragments
    Write-Host "Disabled fragments: $($disabled -join ', ')"
#>
function Get-DisabledFragments {
    [CmdletBinding()]
    [OutputType([string[]])]
    param(
        [string]$ProfileDir
    )

    $config = Get-FragmentConfig -ProfileDir $ProfileDir
    return $config.DisabledFragments
}

<#
.SYNOPSIS
    Gets the load order override.

.DESCRIPTION
    Returns the configured load order override, if any.

.PARAMETER ProfileDir
    Optional. Path to the profile directory.

.OUTPUTS
    System.String[]. Array of fragment names in load order, or empty array if not configured.

.EXAMPLE
    $loadOrder = Get-FragmentLoadOrderOverride
    if ($loadOrder.Count -gt 0) {
        Write-Host "Using custom load order"
    }
#>
function Get-FragmentLoadOrderOverride {
    [CmdletBinding()]
    [OutputType([string[]])]
    param(
        [string]$ProfileDir
    )

    $config = Get-FragmentConfig -ProfileDir $ProfileDir
    return $config.LoadOrder
}

<#
.SYNOPSIS
    Gets environment-specific fragment sets.

.DESCRIPTION
    Returns the configured environment sets, which map environment names to
    arrays of fragment names.

.PARAMETER ProfileDir
    Optional. Path to the profile directory.

.OUTPUTS
    System.Collections.Hashtable. Hashtable mapping environment names to fragment arrays.

.EXAMPLE
    $environments = Get-FragmentEnvironments
    if ($environments.ContainsKey('minimal')) {
        $minimalFragments = $environments['minimal']
    }
#>
function Get-FragmentEnvironments {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [string]$ProfileDir
    )

    $config = Get-FragmentConfig -ProfileDir $ProfileDir
    return $config.Environments
}

<#
.SYNOPSIS
    Gets the current environment's fragment set.

.DESCRIPTION
    Returns the fragment set for the current environment (from $env:PS_PROFILE_ENVIRONMENT),
    or $null if no environment is set or the environment doesn't exist.

.PARAMETER ProfileDir
    Optional. Path to the profile directory.

.OUTPUTS
    System.String[]. Array of fragment names for the current environment, or $null.

.EXAMPLE
    $currentEnvFragments = Get-CurrentEnvironmentFragments
    if ($currentEnvFragments) {
        Write-Host "Environment active: $($currentEnvFragments -join ', ')"
    }
#>
function Get-CurrentEnvironmentFragments {
    [CmdletBinding()]
    [OutputType([string[]])]
    param(
        [string]$ProfileDir
    )

    $currentEnvironment = $env:PS_PROFILE_ENVIRONMENT
    if ([string]::IsNullOrWhiteSpace($currentEnvironment)) {
        return $null
    }

    $environments = Get-FragmentEnvironments -ProfileDir $ProfileDir
    if ($environments.ContainsKey($currentEnvironment)) {
        return $environments[$currentEnvironment]
    }

    return $null
}

<#
.SYNOPSIS
    Gets feature flags.

.DESCRIPTION
    Returns the configured feature flags.

.PARAMETER ProfileDir
    Optional. Path to the profile directory.

.OUTPUTS
    System.Collections.Hashtable. Hashtable mapping feature flag names to values.

.EXAMPLE
    $flags = Get-FragmentFeatureFlags
    if ($flags.enableAdvancedFeatures) {
        # Enable advanced features
    }
#>
function Get-FragmentFeatureFlags {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [string]$ProfileDir
    )

    $config = Get-FragmentConfig -ProfileDir $ProfileDir
    return $config.FeatureFlags
}

<#
.SYNOPSIS
    Gets performance configuration.

.DESCRIPTION
    Returns the performance configuration settings.

.PARAMETER ProfileDir
    Optional. Path to the profile directory.

.OUTPUTS
    System.Collections.Hashtable. Hashtable with batchLoad and maxFragmentTime keys.

.EXAMPLE
    $perf = Get-FragmentPerformanceConfig
    if ($perf.batchLoad) {
        Write-Host "Batch loading enabled"
    }
#>
function Get-FragmentPerformanceConfig {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [string]$ProfileDir
    )

    $config = Get-FragmentConfig -ProfileDir $ProfileDir
    return $config.Performance
}

Export-ModuleMember -Function @(
    'Get-FragmentConfig',
    'Get-FragmentConfigValue',
    'Get-DisabledFragments',
    'Get-FragmentLoadOrderOverride',
    'Get-FragmentEnvironments',
    'Get-CurrentEnvironmentFragments',
    'Get-FragmentFeatureFlags',
    'Get-FragmentPerformanceConfig'
)

