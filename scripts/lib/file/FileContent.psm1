<#
scripts/lib/FileContent.psm1

.SYNOPSIS
    File content reading utilities.

.DESCRIPTION
    Provides functions for reading file content with consistent error handling and
    performance optimizations. Centralizes file reading patterns that are duplicated
    across multiple scripts.

.NOTES
    Module Version: 1.0.0
    PowerShell Version: 3.0+
    
    This module uses strict mode for enhanced error checking.
#>

# Enable strict mode for enhanced error checking
Set-StrictMode -Version Latest

# Import ErrorHandling module if available for consistent error action preference handling
$errorHandlingModulePath = Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'core' 'ErrorHandling.psm1'
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
    Reads file content as a raw string.

.DESCRIPTION
    Reads the entire contents of a file as a single string. Provides consistent error
    handling and performance optimizations. Returns empty string if file doesn't exist
    or cannot be read (unless ErrorAction is Stop).

.PARAMETER Path
    Path to the file to read.

.PARAMETER ErrorAction
    Action to take if file cannot be read. Defaults to SilentlyContinue.
    Use Stop to throw an error if file cannot be read.

.OUTPUTS
    System.String. The file contents, or empty string if file cannot be read.

.EXAMPLE
    $content = Read-FileContent -Path "script.ps1"
    if ($content) {
        # Process content
    }

.EXAMPLE
    $content = Read-FileContent -Path "script.ps1" -ErrorAction Stop
    # Throws error if file cannot be read
#>
function Read-FileContent {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Path
    )

    $errorActionPreference = if ($PSBoundParameters.ContainsKey('ErrorAction')) {
        $PSBoundParameters['ErrorAction']
    }
    else {
        'SilentlyContinue'
    }

    # Use Validation module if available
    if (Get-Command Test-ValidPath -ErrorAction SilentlyContinue) {
        if (-not (Test-ValidPath -Path $Path -PathType File)) {
            if ($errorActionPreference -eq 'Stop') {
                throw "File not found: $Path"
            }
            return ""
        }
    }
    else {
        # Fallback to manual validation
        if (-not ($Path -and -not [string]::IsNullOrWhiteSpace($Path) -and (Test-Path -LiteralPath $Path))) {
            if ($errorActionPreference -eq 'Stop') {
                throw "File not found: $Path"
            }
            return ""
        }
    }

    try {
        $content = Get-Content -Path $Path -Raw -ErrorAction $errorActionPreference
        # Normalize empty files - Get-Content -Raw may return whitespace for empty files
        if ([string]::IsNullOrWhiteSpace($content)) {
            return ""
        }
        return $content
    }
    catch {
        if ($errorActionPreference -eq 'Stop') {
            throw "Failed to read file $Path : $($_.Exception.Message)"
        }
        return ""
    }
}

<#
.SYNOPSIS
    Reads file content and returns null if file doesn't exist.

.DESCRIPTION
    Reads file content, returning null if the file doesn't exist or cannot be read.
    Useful for optional file reading scenarios.

.PARAMETER Path
    Path to the file to read.

.OUTPUTS
    System.String or $null. The file contents, or null if file cannot be read.

.EXAMPLE
    $content = Read-FileContentOrNull -Path "optional-config.json"
    if ($content) {
        $config = $content | ConvertFrom-Json
    }
#>
function Read-FileContentOrNull {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Path
    )

    $content = Read-FileContent -Path $Path -ErrorAction SilentlyContinue
    if ([string]::IsNullOrWhiteSpace($content)) {
        return $null
    }
    return $content
}

Export-ModuleMember -Function @(
    'Read-FileContent',
    'Read-FileContentOrNull'
)
