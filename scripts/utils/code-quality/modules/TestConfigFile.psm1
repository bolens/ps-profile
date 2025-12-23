<#
scripts/utils/code-quality/modules/TestConfigFile.psm1

.SYNOPSIS
    Configuration file utilities for test runner settings.

.DESCRIPTION
    Provides functions for saving and loading test runner configurations from JSON files.
#>

# Import Logging module
$loggingModulePath = Join-Path (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)))) 'lib' 'core' 'Logging.psm1'
if ($loggingModulePath -and -not [string]::IsNullOrWhiteSpace($loggingModulePath) -and (Test-Path -LiteralPath $loggingModulePath)) {
    Import-Module $loggingModulePath -DisableNameChecking -ErrorAction SilentlyContinue
}

# Import JsonUtilities if available
$jsonUtilitiesPath = Join-Path (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)))) 'lib' 'utilities' 'JsonUtilities.psm1'
if ($jsonUtilitiesPath -and -not [string]::IsNullOrWhiteSpace($jsonUtilitiesPath) -and (Test-Path -LiteralPath $jsonUtilitiesPath)) {
    Import-Module $jsonUtilitiesPath -DisableNameChecking -ErrorAction SilentlyContinue
}

<#
.SYNOPSIS
    Saves current test runner configuration to a JSON file.

.DESCRIPTION
    Serializes the current test runner parameters to a JSON configuration file
    that can be loaded later with Load-TestConfig.

.PARAMETER ConfigPath
    Path to save the configuration file.

.PARAMETER Parameters
    Hashtable of parameter names and values to save.

.OUTPUTS
    None
#>
function Save-TestConfig {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ConfigPath,
        [Parameter(Mandatory)]
        [hashtable]$Parameters
    )

    try {
        # Filter out null values and convert to serializable format
        $config = @{}
        foreach ($key in $Parameters.Keys) {
            $value = $Parameters[$key]
            
            # Skip null, empty strings (unless they're meaningful), and certain internal parameters
            if ($null -eq $value) {
                continue
            }
            
            # Skip switch parameters that are false
            if ($value -is [bool] -and -not $value) {
                continue
            }
            
            # Skip empty arrays
            if ($value -is [array] -and $value.Count -eq 0) {
                continue
            }
            
            # Convert switch parameters to boolean
            if ($value -is [switch]) {
                $config[$key] = $value.IsPresent
            }
            else {
                $config[$key] = $value
            }
        }

        # Ensure directory exists
        $configDir = Split-Path $ConfigPath -Parent
        if ($configDir -and -not [string]::IsNullOrWhiteSpace($configDir) -and -not (Test-Path -LiteralPath $configDir)) {
            New-Item -ItemType Directory -Path $configDir -Force | Out-Null
        }

        # Save to JSON
        if (Get-Command 'Write-JsonFile' -ErrorAction SilentlyContinue) {
            Write-JsonFile -Path $ConfigPath -InputObject $config -Depth 10 -EnsureDirectory
        }
        else {
            $config | ConvertTo-Json -Depth 10 | Set-Content -Path $ConfigPath -Encoding UTF8
        }

        Write-ScriptMessage -Message "Configuration saved to: $ConfigPath"
    }
    catch {
        Write-ScriptMessage -Message "Failed to save configuration: $($_.Exception.Message)" -LogLevel 'Error'
        throw
    }
}

<#
.SYNOPSIS
    Loads test runner configuration from a JSON file.

.DESCRIPTION
    Reads a JSON configuration file and returns a hashtable of parameters
    that can be passed to the test runner.

.PARAMETER ConfigPath
    Path to the configuration file to load.

.OUTPUTS
    Hashtable - Parameter names and values
#>
function Load-TestConfig {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory)]
        [string]$ConfigPath
    )

    if ($ConfigPath -and -not [string]::IsNullOrWhiteSpace($ConfigPath) -and -not (Test-Path -LiteralPath $ConfigPath)) {
        throw "Configuration file not found: $ConfigPath"
    }

    try {
        $configContent = Get-Content $ConfigPath -Raw -ErrorAction Stop
        
        if (Get-Command 'Read-JsonFile' -ErrorAction SilentlyContinue) {
            $config = Read-JsonFile -Path $ConfigPath
        }
        else {
            $config = $configContent | ConvertFrom-Json | ConvertTo-Hashtable
        }

        # Convert back to proper types
        $parameters = @{}
        foreach ($key in $config.Keys) {
            $value = $config[$key]
            
            # Convert boolean back to switch if needed (handled in parameter binding)
            $parameters[$key] = $value
        }

        Write-ScriptMessage -Message "Configuration loaded from: $ConfigPath"
        return $parameters
    }
    catch {
        Write-ScriptMessage -Message "Failed to load configuration: $($_.Exception.Message)" -LogLevel 'Error'
        throw
    }
}

<#
.SYNOPSIS
    Helper function to convert PSCustomObject to Hashtable.

.DESCRIPTION
    Recursively converts a PSCustomObject (from ConvertFrom-Json) to a Hashtable.
#>
function ConvertTo-Hashtable {
    param(
        [Parameter(ValueFromPipeline)]
        [object]$InputObject
    )

    process {
        if ($null -eq $InputObject) {
            return $null
        }

        if ($InputObject -is [hashtable]) {
            return $InputObject
        }

        if ($InputObject -is [PSCustomObject]) {
            $hash = @{}
            $InputObject.PSObject.Properties | ForEach-Object {
                $hash[$_.Name] = ConvertTo-Hashtable -InputObject $_.Value
            }
            return $hash
        }

        if ($InputObject -is [System.Array]) {
            return $InputObject | ForEach-Object { ConvertTo-Hashtable -InputObject $_ }
        }

        return $InputObject
    }
}

Export-ModuleMember -Function @(
    'Save-TestConfig',
    'Load-TestConfig',
    'ConvertTo-Hashtable'
)

