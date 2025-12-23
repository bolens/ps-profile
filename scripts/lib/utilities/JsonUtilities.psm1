<#
scripts/lib/JsonUtilities.psm1

.SYNOPSIS
    JSON file read and write utilities with error handling.

.DESCRIPTION
    Provides standardized functions for reading and writing JSON files with
    consistent error handling, encoding, and depth settings. This centralizes
    JSON operations used across multiple scripts.

.NOTES
    Module Version: 1.0.0
    PowerShell Version: 3.0+
#>

# Import SafeImport module if available for safer imports
# Note: We need to use manual check here since SafeImport itself uses Validation
$safeImportModulePath = Join-Path (Split-Path -Parent $PSScriptRoot) 'core' 'SafeImport.psm1'
if ($safeImportModulePath -and -not [string]::IsNullOrWhiteSpace($safeImportModulePath) -and (Test-Path -LiteralPath $safeImportModulePath)) {
    Import-Module $safeImportModulePath -DisableNameChecking -ErrorAction SilentlyContinue
}

# Import ErrorHandling module if available for consistent error action preference handling
$errorHandlingModulePath = Join-Path (Split-Path -Parent $PSScriptRoot) 'core' 'ErrorHandling.psm1'
if (Get-Command Import-ModuleSafely -ErrorAction SilentlyContinue) {
    Import-ModuleSafely -ModulePath $errorHandlingModulePath -DisableNameChecking -ErrorAction SilentlyContinue
}
else {
    # Fallback to manual validation
    if ($errorHandlingModulePath -and -not [string]::IsNullOrWhiteSpace($errorHandlingModulePath) -and (Test-Path -LiteralPath $errorHandlingModulePath)) {
        Import-Module $errorHandlingModulePath -DisableNameChecking -ErrorAction SilentlyContinue
    }
}

<#
.SYNOPSIS
    Reads a JSON file and converts it to a PowerShell object.

.DESCRIPTION
    Reads a JSON file from disk and converts it to a PowerShell object (hashtable
    or PSCustomObject). Handles errors gracefully and provides consistent behavior
    across scripts.

.PARAMETER Path
    Path to the JSON file to read.

.PARAMETER ErrorAction
    Controls how the function responds to errors. This is a common parameter available to all advanced functions.
    Defaults to 'Stop'.

.OUTPUTS
    Object (hashtable or PSCustomObject) containing the parsed JSON data.

.EXAMPLE
    $config = Read-JsonFile -Path 'config.json'
#>
function Read-JsonFile {
    [CmdletBinding()]
    [OutputType([object])]
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    # Get ErrorAction preference using ErrorHandling module if available
    if (Get-Command Get-ErrorActionPreference -ErrorAction SilentlyContinue) {
        $errorActionPreference = Get-ErrorActionPreference -PSBoundParameters $PSBoundParameters -Default 'Stop'
    }
    else {
        # Fallback to manual extraction
        $errorActionPreference = if ($PSBoundParameters.ContainsKey('ErrorAction')) {
            $PSBoundParameters['ErrorAction']
        }
        else {
            'Stop'
        }
    }

    if (-not (Test-Path -Path $Path)) {
        $errorMessage = "JSON file not found: $Path"
        if ($errorActionPreference -eq 'Stop') {
            throw $errorMessage
        }
        Write-Error -Message $errorMessage -ErrorAction $errorActionPreference
        return $null
    }

    try {
        $content = Get-Content -Path $Path -Raw -Encoding UTF8 -ErrorAction Stop
        if ([string]::IsNullOrWhiteSpace($content)) {
            Write-Warning "JSON file is empty: $Path"
            return $null
        }

        $result = $content | ConvertFrom-Json -ErrorAction Stop
        return $result
    }
    catch {
        $errorMessage = "Failed to read JSON file '$Path': $($_.Exception.Message)"
        if ($errorActionPreference -eq 'Stop') {
            throw $errorMessage
        }
        Write-Error -Message $errorMessage -ErrorAction $errorActionPreference -Exception $_.Exception
        return $null
    }
}

<#
.SYNOPSIS
    Writes a PowerShell object to a JSON file.

.DESCRIPTION
    Converts a PowerShell object to JSON and writes it to a file. Ensures the
    output directory exists and uses consistent encoding and depth settings.

.PARAMETER Path
    Path to the JSON file to write.

.PARAMETER InputObject
    The object to convert to JSON and write.

.PARAMETER Depth
    Maximum depth for JSON serialization. Defaults to 10.

.PARAMETER Encoding
    File encoding. Defaults to UTF8.

.PARAMETER EnsureDirectory
    If specified, ensures the output directory exists before writing.

.PARAMETER ErrorAction
    Controls how the function responds to errors. This is a common parameter available to all advanced functions.
    Defaults to 'Stop'.

.EXAMPLE
    $data = @{ Name = 'Test'; Value = 123 }
    Write-JsonFile -Path 'output.json' -InputObject $data
#>
function Write-JsonFile {
    [CmdletBinding()]
    [OutputType([void])]
    param(
        [Parameter(Mandatory)]
        [string]$Path,

        [Parameter(Mandatory, ValueFromPipeline)]
        [object]$InputObject,

        [int]$Depth = 10,

        [string]$Encoding = 'UTF8',

        [switch]$EnsureDirectory
    )

    # Get ErrorAction preference using ErrorHandling module if available
    if (Get-Command Get-ErrorActionPreference -ErrorAction SilentlyContinue) {
        $errorActionPreference = Get-ErrorActionPreference -PSBoundParameters $PSBoundParameters -Default 'Stop'
    }
    else {
        # Fallback to manual extraction
        $errorActionPreference = if ($PSBoundParameters.ContainsKey('ErrorAction')) {
            $PSBoundParameters['ErrorAction']
        }
        else {
            'Stop'
        }
    }

    # Ensure directory exists if requested
    if ($EnsureDirectory) {
        $directory = Split-Path -Path $Path -Parent
        if ($directory -and -not (Test-Path -Path $directory)) {
            try {
                if (Get-Command Ensure-DirectoryExists -ErrorAction SilentlyContinue) {
                    Ensure-DirectoryExists -Path $directory
                }
                else {
                    New-Item -ItemType Directory -Path $directory -Force | Out-Null
                }
            }
            catch {
                $errorMessage = "Failed to create directory for JSON file: $($_.Exception.Message)"
                if ($errorActionPreference -eq 'Stop') {
                    throw $errorMessage
                }
                Write-Error -Message $errorMessage -ErrorAction $errorActionPreference -Exception $_.Exception
                return
            }
        }
    }

    try {
        $jsonContent = $InputObject | ConvertTo-Json -Depth $Depth -ErrorAction Stop
        
        # Use Set-Content with encoding
        $encodingParam = @{}
        if ($Encoding -eq 'UTF8') {
            $encodingParam['Encoding'] = 'UTF8'
        }
        else {
            $encodingParam['Encoding'] = $Encoding
        }

        Set-Content -Path $Path -Value $jsonContent @encodingParam -ErrorAction Stop
        Write-Verbose "JSON file written: $Path"
    }
    catch {
        $errorMessage = "Failed to write JSON file '$Path': $($_.Exception.Message)"
        if ($errorActionPreference -eq 'Stop') {
            throw $errorMessage
        }
        Write-Error -Message $errorMessage -ErrorAction $errorActionPreference -Exception $_.Exception
    }
}

# Export functions
Export-ModuleMember -Function @(
    'Read-JsonFile',
    'Write-JsonFile'
)
