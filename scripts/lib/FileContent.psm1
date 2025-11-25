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
#>

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
        [string]$Path
    )

    $errorActionPreference = if ($PSBoundParameters.ContainsKey('ErrorAction')) {
        $PSBoundParameters['ErrorAction']
    }
    else {
        'SilentlyContinue'
    }

    if (-not (Test-Path $Path)) {
        if ($errorActionPreference -eq 'Stop') {
            throw "File not found: $Path"
        }
        return ""
    }

    try {
        return Get-Content -Path $Path -Raw -ErrorAction $errorActionPreference
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

