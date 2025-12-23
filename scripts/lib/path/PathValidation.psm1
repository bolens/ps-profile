<#
scripts/lib/PathValidation.psm1

.SYNOPSIS
    Path validation utilities.

.DESCRIPTION
    Provides functions for validating and resolving paths with defaults.
#>

<#
.SYNOPSIS
    Gets a default path if not provided, otherwise validates the provided path.

.DESCRIPTION
    Helper function for scripts that accept an optional Path parameter.
    If Path is null or empty, returns the default path (typically profile.d).
    If Path is provided, validates it exists and returns it.

.PARAMETER Path
    The optional path parameter from the script.

.PARAMETER DefaultPath
    The default path to use if Path is not provided.

.PARAMETER PathType
    The type of path to validate. 'Any' (default), 'File', or 'Directory'.

.OUTPUTS
    System.String. The resolved path.

.EXAMPLE
    $resolvedPath = Resolve-DefaultPath -Path $Path -DefaultPath (Get-ProfileDirectory -ScriptPath $PSScriptRoot)
#>
function Resolve-DefaultPath {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [string]$Path,

        [Parameter(Mandatory)]
        [string]$DefaultPath,

        [ValidateSet('Any', 'File', 'Directory')]
        [string]$PathType = 'Any'
    )

    if ([string]::IsNullOrWhiteSpace($Path)) {
        return $DefaultPath
    }

    # Validate the provided path (throws if invalid)
    if (Get-Command Test-PathExists -ErrorAction SilentlyContinue) {
        $null = Test-PathExists -Path $Path -PathType $PathType
    }
    else {
        # Fallback validation
        if (-not (Test-Path -Path $Path)) {
            throw "Path does not exist: $Path"
        }
        
        # Validate path type if specified
        if ($PathType -eq 'File' -and -not (Test-Path -Path $Path -PathType Leaf)) {
            throw "Path exists but is not a file: $Path"
        }
        
        if ($PathType -eq 'Directory' -and -not (Test-Path -Path $Path -PathType Container)) {
            throw "Path exists but is not a directory: $Path"
        }
    }
    return $Path
}

Export-ModuleMember -Function Resolve-DefaultPath

