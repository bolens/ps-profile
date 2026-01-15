<#
scripts/lib/PathValidation.psm1

.SYNOPSIS
    Path validation utilities.

.DESCRIPTION
    Provides functions for validating and resolving paths with defaults.

.NOTES
    Module Version: 2.0.0
    PowerShell Version: 5.0+ (for enum support)
    
    This module now uses enums for type-safe path type handling.
#>

# Import CommonEnums for FileSystemPathType enum
$commonEnumsPath = Join-Path (Split-Path -Parent $PSScriptRoot) 'core' 'CommonEnums.psm1'
if ($commonEnumsPath -and (Test-Path -LiteralPath $commonEnumsPath)) {
    Import-Module $commonEnumsPath -DisableNameChecking -ErrorAction SilentlyContinue
}

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
    The type of path to validate. Must be a FileSystemPathType enum value. Defaults to Any.

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
        [ValidateNotNullOrEmpty()]
        [string]$DefaultPath,

        [FileSystemPathType]$PathType = [FileSystemPathType]::Any
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
        $pathTypeString = $PathType.ToString()
        if ($pathTypeString -eq 'File' -and -not (Test-Path -Path $Path -PathType Leaf)) {
            throw "Path exists but is not a file: $Path"
        }
        
        if ($pathTypeString -eq 'Directory' -and -not (Test-Path -Path $Path -PathType Container)) {
            throw "Path exists but is not a directory: $Path"
        }
    }
    return $Path
}

Export-ModuleMember -Function Resolve-DefaultPath

