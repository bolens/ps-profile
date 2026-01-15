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

# Import CommonEnums first - needed by Validation which is used by SafeImport and PathResolution
# CommonEnums must be imported before any module that uses FileSystemPathType enum
# Use -Force and -Global to ensure types are available globally at parse time
$commonEnumsPath = Join-Path (Split-Path -Parent $PSScriptRoot) 'core' 'CommonEnums.psm1'
if ($commonEnumsPath -and -not [string]::IsNullOrWhiteSpace($commonEnumsPath) -and (Test-Path -LiteralPath $commonEnumsPath)) {
    try {
        Import-Module $commonEnumsPath -DisableNameChecking -Force -Global -ErrorAction Stop
    }
    catch {
        # CommonEnums is critical - log error but continue (Validation will also try to import it)
        $debugLevel = 0
        if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel) -and $debugLevel -ge 2) {
            Write-Verbose "[fragment-config.init] Failed to import CommonEnums module: $($_.Exception.Message). Validation module will attempt to import it."
        }
    }
}

# Import SafeImport module if available for safer imports
# Note: We need to use manual check here since SafeImport itself uses Validation
$safeImportModulePath = Join-Path (Split-Path -Parent $PSScriptRoot) 'core' 'SafeImport.psm1'
if ($safeImportModulePath -and -not [string]::IsNullOrWhiteSpace($safeImportModulePath) -and (Test-Path -LiteralPath $safeImportModulePath)) {
    Import-Module $safeImportModulePath -DisableNameChecking -ErrorAction SilentlyContinue
}

# Import JsonUtilities for JSON operations
# JsonUtilities is in scripts/lib/utilities/, not scripts/lib/fragment/
$jsonModulePath = Join-Path (Split-Path -Parent $PSScriptRoot) 'utilities' 'JsonUtilities.psm1'
if (Get-Command Import-ModuleSafely -ErrorAction SilentlyContinue) {
    $null = Import-ModuleSafely -ModulePath $jsonModulePath -ErrorAction SilentlyContinue
}
else {
    # Fallback to manual validation
    if ($jsonModulePath -and -not [string]::IsNullOrWhiteSpace($jsonModulePath) -and (Test-Path -LiteralPath $jsonModulePath)) {
        try {
            Import-Module $jsonModulePath -ErrorAction Stop
        }
        catch {
            $debugLevel = 0
            if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel)) {
                if ($debugLevel -ge 2) {
                    Write-Verbose "[fragment-config.init] Failed to import JsonUtilities module: $($_.Exception.Message). JSON operations may be limited."
                }
                # Level 3: Log detailed error information
                if ($debugLevel -ge 3) {
                    Write-Host "  [fragment-config.init] JsonUtilities import error details - Exception: $($_.Exception.GetType().FullName), Message: $($_.Exception.Message)" -ForegroundColor DarkGray
                }
            }
        }
    }
}

# PathResolution import is deferred - only loaded when Get-ProfileDirectory is actually needed
# This avoids parse-time errors when FileSystemPathType is not yet available
# PathResolution is in scripts/lib/path/, not scripts/lib/fragment/
# Note: PathResolution uses Validation which requires FileSystemPathType from CommonEnums
# CommonEnums should be imported early in the profile before this module is loaded

# Import Logging for consistent output
# Logging is in scripts/lib/core/, not scripts/lib/fragment/
$loggingModulePath = Join-Path (Split-Path -Parent $PSScriptRoot) 'core' 'Logging.psm1'
if (Get-Command Import-ModuleSafely -ErrorAction SilentlyContinue) {
    $null = Import-ModuleSafely -ModulePath $loggingModulePath -ErrorAction SilentlyContinue
}
else {
    # Fallback to manual validation
    if ($loggingModulePath -and -not [string]::IsNullOrWhiteSpace($loggingModulePath) -and (Test-Path -LiteralPath $loggingModulePath)) {
        try {
            Import-Module $loggingModulePath -ErrorAction Stop
        }
        catch {
            $debugLevel = 0
            if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel)) {
                if ($debugLevel -ge 1) {
                    $errorMessage = "Failed to import Logging module, logging features may be limited"
                    $errorDetails = "Error: $($_.Exception.Message) (Type: $($_.Exception.GetType().Name))"
                    if ($_.InvocationInfo.ScriptLineNumber -gt 0) {
                        $errorDetails += " at line $($_.InvocationInfo.ScriptLineNumber)"
                    }
                    Write-Verbose "[fragment-config.init] $errorMessage - $errorDetails"
                }
                # Level 3: Log detailed error information
                if ($debugLevel -ge 3) {
                    Write-Host "  [fragment-config.init] Logging import error details - Exception: $($_.Exception.GetType().FullName), Message: $($_.Exception.Message), Line: $($_.InvocationInfo.ScriptLineNumber)" -ForegroundColor DarkGray
                }
            }
        }
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
    $debugLevel = 0
    if (-not $ConfigPath) {
        if (-not $ProfileDir) {
            # Try to resolve from current context
            # Lazy-load PathResolution only when Get-ProfileDirectory is needed
            if (-not (Get-Command Get-ProfileDirectory -ErrorAction SilentlyContinue)) {
                # Try to import PathResolution if not already available
                $pathModulePath = Join-Path (Split-Path -Parent $PSScriptRoot) 'path' 'PathResolution.psm1'
                if ($pathModulePath -and -not [string]::IsNullOrWhiteSpace($pathModulePath) -and (Test-Path -LiteralPath $pathModulePath)) {
                    try {
                        if (Get-Command Import-ModuleSafely -ErrorAction SilentlyContinue) {
                            $null = Import-ModuleSafely -ModulePath $pathModulePath -ErrorAction SilentlyContinue
                        }
                        else {
                            Import-Module $pathModulePath -ErrorAction SilentlyContinue -DisableNameChecking
                        }
                    }
                    catch {
                        # PathResolution import failed - non-fatal, will use fallback
                        $debugLevel = 0
                        if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel) -and $debugLevel -ge 2) {
                            Write-Verbose "[fragment-config.get] Failed to import PathResolution module: $($_.Exception.Message). Using fallback path resolution."
                        }
                    }
                }
            }
            
            if (Get-Command Get-ProfileDirectory -ErrorAction SilentlyContinue) {
                try {
                    $ProfileDir = Get-ProfileDirectory -ScriptPath $PSScriptRoot
                    # Level 3: Log profile directory resolution
                    if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel) -and $debugLevel -ge 3) {
                        Write-Host "  [fragment-config.get] Resolved profile directory: $ProfileDir" -ForegroundColor DarkGray
                    }
                }
                catch {
                    # Fallback: try to find profile directory relative to common locations
                    $ProfileDir = $null
                    # Level 2: Log profile directory resolution failure
                    if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel) -and $debugLevel -ge 2) {
                        Write-Verbose "[fragment-config.get] Failed to resolve profile directory: $($_.Exception.Message)"
                    }
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
        # Level 3: Log config path resolution
        if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel) -and $debugLevel -ge 3) {
            Write-Verbose "[fragment-config.get] Resolved config path: $ConfigPath"
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
    # Use Validation module if available
    if (Get-Command Test-ValidPath -ErrorAction SilentlyContinue) {
        if (-not (Test-ValidPath -Path $ConfigPath -PathType File)) {
            # Level 3: Log config file not found
            if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel) -and $debugLevel -ge 3) {
                Write-Host "  [fragment-config.get] Config file not found: $ConfigPath, using default configuration" -ForegroundColor DarkGray
            }
            return $config
        }
    }
    else {
        # Fallback to manual validation
        if (-not ($ConfigPath -and -not [string]::IsNullOrWhiteSpace($ConfigPath) -and (Test-Path -LiteralPath $ConfigPath))) {
            # Level 3: Log config file not found
            if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel) -and $debugLevel -ge 3) {
                Write-Host "  [fragment-config.get] Config file not found: $ConfigPath, using default configuration" -ForegroundColor DarkGray
            }
            return $config
        }
    }
    
    # Level 2: Log config file found
    if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel) -and $debugLevel -ge 2) {
        Write-Verbose "[fragment-config.get] Loading configuration from: $ConfigPath"
    }

    try {
        $configContent = Get-Content -Path $ConfigPath -Raw -ErrorAction Stop
        if ([string]::IsNullOrWhiteSpace($configContent)) {
            # Level 2: Log empty config file
            if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel) -and $debugLevel -ge 2) {
                Write-Verbose "[fragment-config.get] Config file is empty, using default configuration"
            }
            return $config
        }
        
        # Level 3: Log config file size
        if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel) -and $debugLevel -ge 3) {
            $contentLength = $configContent.Length
            Write-Host "  [fragment-config.get] Config file content length: $contentLength characters" -ForegroundColor DarkGray
        }

        # Parse JSON with explicit error handling
        try {
            $configObj = $configContent | ConvertFrom-Json -ErrorAction Stop
            # Level 3: Log successful JSON parsing
            if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel) -and $debugLevel -ge 3) {
                Write-Host "  [fragment-config.get] Successfully parsed JSON configuration" -ForegroundColor DarkGray
            }
        }
        catch {
            # Level 1: Log JSON parsing error
            $errorMessage = "Invalid JSON in config file: $($_.Exception.Message)"
            $debugLevel = 0
            if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel)) {
                if ($debugLevel -ge 1) {
                    if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                        Write-StructuredError -ErrorRecord $_ -OperationName 'fragment-config.get' -Context @{
                            ConfigPath = $ConfigPath
                            ErrorType  = 'InvalidJSON'
                        }
                    }
                    else {
                        Write-Error $errorMessage -ErrorAction Continue
                    }
                }
                # Level 3: Log detailed error information
                if ($debugLevel -ge 3) {
                    Write-Host "  [fragment-config.get] JSON parsing error details - ConfigPath: $ConfigPath, Exception: $($_.Exception.GetType().FullName), Message: $($_.Exception.Message), Stack: $($_.ScriptStackTrace)" -ForegroundColor DarkGray
                }
            }
            else {
                # Always log critical errors even if debug is off
                if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                    Write-StructuredError -ErrorRecord $_ -OperationName 'fragment-config.get' -Context @{
                        ConfigPath = $ConfigPath
                        ErrorType  = 'InvalidJSON'
                    }
                }
                else {
                    Write-Error $errorMessage -ErrorAction Continue
                }
            }
            throw $errorMessage
        }

        # Parse disabled fragments
        if ($configObj.disabled) {
            $config.DisabledFragments = @($configObj.disabled)
            # Level 3: Log disabled fragments
            if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel) -and $debugLevel -ge 3) {
                Write-Host "  [fragment-config.get] Parsed disabled fragments: $($config.DisabledFragments -join ', ')" -ForegroundColor DarkGray
            }
        }

        # Parse load order override
        if ($configObj.loadOrder) {
            $config.LoadOrder = @($configObj.loadOrder)
            # Level 3: Log load order
            if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel) -and $debugLevel -ge 3) {
                Write-Host "  [fragment-config.get] Parsed load order: $($config.LoadOrder -join ', ')" -ForegroundColor DarkGray
            }
        }

        # Parse environment sets
        if ($configObj.environments) {
            $configObj.environments.PSObject.Properties | ForEach-Object {
                $config.Environments[$_.Name] = @($_.Value)
            }
            # Level 3: Log environment sets
            if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel) -and $debugLevel -ge 3) {
                $envNames = $config.Environments.Keys -join ', '
                Write-Host "  [fragment-config.get] Parsed environment sets: $envNames" -ForegroundColor DarkGray
            }
        }

        # Parse feature flags
        if ($configObj.featureFlags) {
            $configObj.featureFlags.PSObject.Properties | ForEach-Object {
                $config.FeatureFlags[$_.Name] = $_.Value
            }
            # Level 3: Log feature flags
            if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel) -and $debugLevel -ge 3) {
                $flagNames = $config.FeatureFlags.Keys -join ', '
                Write-Verbose "[fragment-config.get] Parsed feature flags: $flagNames"
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
            # Level 3: Log performance configuration
            if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel) -and $debugLevel -ge 3) {
                Write-Host "  [fragment-config.get] Parsed performance config - batchLoad: $($config.Performance.batchLoad), maxFragmentTime: $($config.Performance.maxFragmentTime)" -ForegroundColor DarkGray
            }
        }
        
        # Level 2: Log successful configuration load
        if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel) -and $debugLevel -ge 2) {
            Write-Verbose "[fragment-config.get] Successfully loaded configuration from: $ConfigPath"
        }
    }
    catch {
        $errorMessage = "Failed to load fragment config from '$ConfigPath': $($_.Exception.Message)"
        $debugLevel = 0
        if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel)) {
            if ($debugLevel -ge 1) {
                if (Get-Command Write-StructuredWarning -ErrorAction SilentlyContinue) {
                    Write-StructuredWarning -Message $errorMessage -OperationName 'fragment-config.get' -Context @{
                        ConfigPath = $ConfigPath
                        Error      = $_.Exception.Message
                    }
                }
                elseif (Get-Command Write-ScriptMessage -ErrorAction SilentlyContinue) {
                    Write-ScriptMessage -Message $errorMessage -IsWarning
                }
                else {
                    Write-Warning $errorMessage
                }
            }
            # Level 3: Log detailed error information
            if ($debugLevel -ge 3) {
                Write-Host "  [fragment-config.get] Config load error details - Exception: $($_.Exception.GetType().FullName), Message: $($_.Exception.Message), ConfigPath: $ConfigPath" -ForegroundColor DarkGray
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
    [OutputType([object])]  # Generic return type - can be any config value type
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
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

<#
.SYNOPSIS
    Parses metadata from a fragment file.

.DESCRIPTION
    Extracts metadata (Tier, Dependencies, Environment tags) from a fragment file header.
    Supports both explicit declarations and automatic detection.

.PARAMETER FragmentFile
    The fragment file to parse. Can be a FileInfo object or path string.

.OUTPUTS
    System.Collections.Hashtable. Hashtable with keys:
    - Tier: core|essential|standard|optional
    - Dependencies: Array of fragment names
    - Environments: Array of environment names (from explicit tags)
    - Keywords: Array of detected keywords for category matching

.EXAMPLE
    $metadata = Get-FragmentMetadata -FragmentFile $fragmentFile
    Write-Host "Tier: $($metadata.Tier)"
#>
function Get-FragmentMetadata {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory)]
        [object]$FragmentFile
    )

    $filePath = if ($FragmentFile -is [System.IO.FileInfo]) {
        $FragmentFile.FullName
    }
    else {
        $FragmentFile
    }

    $metadata = @{
        Tier         = 'optional'
        Dependencies = @()
        Environments = @()
        Keywords     = @()
    }

    # Use Validation module if available
    if (Get-Command Test-ValidPath -ErrorAction SilentlyContinue) {
        if (-not (Test-ValidPath -Path $filePath -PathType File)) {
            return $metadata
        }
    }
    else {
        if (-not ($filePath -and -not [string]::IsNullOrWhiteSpace($filePath) -and (Test-Path -LiteralPath $filePath))) {
            return $metadata
        }
    }

    try {
        $content = if (Get-Command Read-FileContent -ErrorAction SilentlyContinue) {
            Read-FileContent -Path $filePath
        }
        else {
            Get-Content -Path $filePath -Raw -ErrorAction Stop
        }

        if ([string]::IsNullOrWhiteSpace($content)) {
            return $metadata
        }

        # Parse Tier
        if ($content -match '(?i)#\s*Tier\s*:\s*(core|essential|standard|optional)') {
            $metadata.Tier = $matches[1].ToLowerInvariant()
        }
        elseif (Get-Command Get-FragmentTier -ErrorAction SilentlyContinue) {
            $metadata.Tier = Get-FragmentTier -FragmentFile $FragmentFile
        }

        # Parse Dependencies
        if ($content -match '(?i)#\s*Dependencies\s*:\s*([^\r\n]+)') {
            $depsLine = $matches[1].Trim()
            $metadata.Dependencies = @($depsLine -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ })
        }
        elseif (Get-Command Get-FragmentDependencies -ErrorAction SilentlyContinue) {
            $metadata.Dependencies = @(Get-FragmentDependencies -FragmentFile $FragmentFile)
        }

        # Parse explicit Environment tags
        # Format: # Environment: minimal, development, cloud
        if ($content -match '(?i)#\s*Environment\s*:\s*([^\r\n]+)') {
            $envLine = $matches[1].Trim()
            $metadata.Environments = @($envLine -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ })
        }

        # Extract keywords from fragment name for category matching
        $fileInfo = if ($FragmentFile -is [System.IO.FileInfo]) {
            $FragmentFile
        }
        else {
            Get-Item -Path $filePath -ErrorAction SilentlyContinue
        }

        if ($fileInfo) {
            $baseName = $fileInfo.BaseName
            $keywords = @($baseName)
            
            # Add category keywords based on fragment name patterns
            if ($baseName -match 'container|docker|podman|kube|helm') { $keywords += 'containers' }
            if ($baseName -match 'aws|azure|gcloud|terraform|cloud') { $keywords += 'cloud' }
            if ($baseName -match 'git|gh') { $keywords += 'git' }
            if ($baseName -match 'npm|pnpm|yarn|bun|package') { $keywords += 'web' }
            if ($baseName -match 'go|rust|python|java|php|deno|dart|swift|julia|dotnet|lang-') { $keywords += 'development' }
            if ($baseName -match 'database|sql|postgres|mysql') { $keywords += 'server' }
            if ($baseName -match 'network|ssh|security') { $keywords += 'server' }
            
            $metadata.Keywords = $keywords
            
            # Level 3: Log metadata extraction details
            $debugLevel = 0
            if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel) -and $debugLevel -ge 3) {
                Write-Verbose "[fragment-config.parse-metadata] Extracted metadata - Tier: $($metadata.Tier), Dependencies: $($metadata.Dependencies -join ', '), Keywords: $($metadata.Keywords -join ', ')"
            }
        }
        
        # Level 2: Log successful metadata parsing
        $debugLevel = 0
        if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel) -and $debugLevel -ge 2) {
            Write-Verbose "[fragment-config.parse-metadata] Successfully parsed metadata for fragment: $filePath"
        }
    }
    catch {
        $debugLevel = 0
        if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel)) {
            if ($debugLevel -ge 1) {
                $errorMessage = "Failed to parse fragment metadata from: $filePath"
                if (Get-Command Write-StructuredWarning -ErrorAction SilentlyContinue) {
                    Write-StructuredWarning -Message $errorMessage -OperationName 'fragment-config.parse-metadata' -Context @{
                        FilePath   = $filePath
                        Error      = $_.Exception.Message
                        LineNumber = $_.InvocationInfo.ScriptLineNumber
                    }
                }
                else {
                    Write-Warning $errorMessage
                }
            }
            if ($debugLevel -ge 2) {
                $errorMessage = "Failed to parse fragment metadata from: $filePath"
                $errorDetails = "Error: $($_.Exception.Message) (Type: $($_.Exception.GetType().Name))"
                if ($_.InvocationInfo.ScriptLineNumber -gt 0) {
                    $errorDetails += " at line $($_.InvocationInfo.ScriptLineNumber)"
                }
                Write-Verbose "[fragment-config.parse-metadata] $errorMessage - $errorDetails"
            }
            # Level 3: Log detailed error information
            if ($debugLevel -ge 3) {
                Write-Host "  [fragment-config.parse-metadata] Metadata parsing error details - Exception: $($_.Exception.GetType().FullName), Message: $($_.Exception.Message), FilePath: $filePath, Line: $($_.InvocationInfo.ScriptLineNumber)" -ForegroundColor DarkGray
            }
        }
    }

    return $metadata
}

Export-ModuleMember -Function @(
    'Get-FragmentConfig',
    'Get-FragmentConfigValue',
    'Get-DisabledFragments',
    'Get-FragmentLoadOrderOverride',
    'Get-FragmentEnvironments',
    'Get-CurrentEnvironmentFragments',
    'Get-FragmentFeatureFlags',
    'Get-FragmentPerformanceConfig',
    'Get-FragmentMetadata'
)
