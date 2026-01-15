<#
scripts/lib/core/Validation.psm1

.SYNOPSIS
    String and path validation utilities.

.DESCRIPTION
    Provides consistent validation functions for strings and paths, reducing
    boilerplate code across modules. Combines null/whitespace checks with
    path existence validation in a single, reusable pattern.

.NOTES
    Module Version: 2.0.0
    PowerShell Version: 5.0+ (for enum support)
    
    This module now uses enums for type-safe path type handling.
#>

# Import CommonEnums for FileSystemPathType enum
# Must be imported before this module is parsed since FileSystemPathType is used in function signatures
# Use -Force to ensure it's loaded even if already imported, and -Global to make types available globally
$commonEnumsPath = Join-Path $PSScriptRoot 'CommonEnums.psm1'
if ($commonEnumsPath -and (Test-Path -LiteralPath $commonEnumsPath)) {
    try {
        Import-Module $commonEnumsPath -DisableNameChecking -Force -Global -ErrorAction Stop
    }
    catch {
        # If CommonEnums import fails, this module cannot function properly
        # Log error but don't throw - let calling code handle the failure
        $debugLevel = 0
        if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel) -and $debugLevel -ge 1) {
            Write-Warning "[validation.init] Failed to import CommonEnums: $($_.Exception.Message). FileSystemPathType will not be available."
        }
    }
}

<#
.SYNOPSIS
    Tests if a string is valid (not null or whitespace).

.DESCRIPTION
    Validates that a string is not null, empty, or whitespace.
    This is a common pattern used throughout the codebase.

.PARAMETER Value
    The value to validate. Accepts any type (uses `[object]` for flexibility) -
    will be converted to string for validation. This allows the function to
    handle strings, paths, and other types that can be converted to strings.

.OUTPUTS
    System.Boolean. Returns $true if the string is valid, $false otherwise.

.EXAMPLE
    if (Test-ValidString -Value $path) {
        # Use the path
    }

.EXAMPLE
    Test-ValidString -Value ""
    # Returns $false

.EXAMPLE
    Test-ValidString -Value $null
    # Returns $false
#>
function Test-ValidString {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory)]
        [AllowNull()]
        # Note: Uses [object] intentionally to accept any type (strings, paths, etc.)
        # The function converts non-string values to strings for validation
        [object]$Value
    )

    if ($null -eq $Value) {
        return $false
    }

    if ($Value -isnot [string]) {
        $Value = $Value.ToString()
    }

    return -not [string]::IsNullOrWhiteSpace($Value)
}

<#
.SYNOPSIS
    Tests if a path is valid and exists.

.DESCRIPTION
    Combines string validation with path existence check. This is a common
    pattern used throughout the codebase: checking if a path is not null/whitespace
    and then verifying it exists.

.PARAMETER Path
    The path to validate. Can be a string, FileInfo, DirectoryInfo, or any object
    that can be converted to a string.

.PARAMETER PathType
    The type of path to validate. 'Any' (default), 'File', or 'Directory'.

.PARAMETER MustExist
    If specified, the path must exist. If not specified, only validates the path
    string is not null/whitespace. Defaults to $true.

.OUTPUTS
    System.Boolean. Returns $true if the path is valid (and exists if MustExist),
    $false otherwise.

.EXAMPLE
    if (Test-ValidPath -Path $modulePath) {
        Import-Module $modulePath
    }

.EXAMPLE
    # Validate path string without checking existence
    Test-ValidPath -Path "C:\temp\file.txt" -MustExist:$false

.EXAMPLE
    # Validate directory specifically
    Test-ValidPath -Path $logDir -PathType Directory
#>
function Test-ValidPath {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory)]
        [AllowNull()]
        # Note: Uses [object] intentionally to accept any path-like type (strings, PathInfo, etc.)
        # The function converts non-string values to strings for path validation
        [object]$Path,

        [FileSystemPathType]$PathType = [FileSystemPathType]::Any,

        [bool]$MustExist = $true
    )

    # Convert Path to string if it's not already
    $pathString = if ($Path -is [string]) {
        $Path
    }
    elseif ($null -ne $Path) {
        $Path.ToString()
    }
    else {
        $null
    }

    # Check if string is valid
    if (-not (Test-ValidString -Value $pathString)) {
        return $false
    }

    # If MustExist is false, only validate the string
    if (-not $MustExist) {
        return $true
    }

    # Check path existence
    if (-not (Test-Path -LiteralPath $pathString -ErrorAction SilentlyContinue)) {
        return $false
    }

    # Convert enum to string
    $pathTypeString = $PathType.ToString()
    
    # Validate path type if specified
    if ($pathTypeString -eq 'File') {
        return (Test-Path -LiteralPath $pathString -PathType Leaf -ErrorAction SilentlyContinue)
    }
    elseif ($pathTypeString -eq 'Directory') {
        return (Test-Path -LiteralPath $pathString -PathType Container -ErrorAction SilentlyContinue)
    }

    return $true
}

<#
.SYNOPSIS
    Asserts that a path is valid and exists, throwing an error if not.

.DESCRIPTION
    Validates a path and throws a descriptive error if validation fails.
    Useful for required parameters or critical path validation.

.PARAMETER Path
    The path to validate.

.PARAMETER PathType
    The type of path to validate. 'Any' (default), 'File', or 'Directory'.

.PARAMETER ParameterName
    Optional parameter name to include in error message. Useful when validating
    function parameters.

.PARAMETER ErrorMessage
    Custom error message. If not provided, generates a default message.

.EXAMPLE
    Assert-ValidPath -Path $configFile -PathType File -ParameterName 'ConfigFile'

.EXAMPLE
    Assert-ValidPath -Path $logDir -PathType Directory -ErrorMessage "Log directory must exist"
#>
function Assert-ValidPath {
    [CmdletBinding()]
    [OutputType([void])]
    param(
        [Parameter(Mandatory)]
        [AllowNull()]
        [object]$Path,

        [FileSystemPathType]$PathType = [FileSystemPathType]::Any,

        [string]$ParameterName,

        [string]$ErrorMessage
    )

    if (Test-ValidPath -Path $Path -PathType $PathType) {
        return
    }

    # Generate error message
    if (-not $ErrorMessage) {
        $pathString = if ($Path -is [string]) {
            $Path
        }
        elseif ($null -ne $Path) {
            $Path.ToString()
        }
        else {
            'null'
        }

        # Convert enum to string
        $pathTypeString = $PathType.ToString()
        $typeText = if ($pathTypeString -ne 'Any') {
            " ($pathTypeString)"
        }
        else {
            ''
        }

        $paramText = if ($ParameterName) {
            "Parameter '$ParameterName': "
        }
        else {
            ''
        }

        $ErrorMessage = "${paramText}Path${typeText} is invalid or does not exist: $pathString"
    }

    throw $ErrorMessage
}

<#
.SYNOPSIS
    Asserts that a string is valid (not null or whitespace), throwing an error if not.

.DESCRIPTION
    Validates a string and throws a descriptive error if it's null or whitespace.
    Useful for required string parameters.

.PARAMETER Value
    The string value to validate.

.PARAMETER ParameterName
    Optional parameter name to include in error message. Useful when validating
    function parameters.

.PARAMETER ErrorMessage
    Custom error message. If not provided, generates a default message.

.EXAMPLE
    Assert-ValidString -Value $name -ParameterName 'Name'

.EXAMPLE
    Assert-ValidString -Value $message -ErrorMessage "Message cannot be empty"
#>
function Assert-ValidString {
    [CmdletBinding()]
    [OutputType([void])]
    param(
        [Parameter(Mandatory)]
        [AllowNull()]
        [object]$Value,

        [string]$ParameterName,

        [string]$ErrorMessage
    )

    if (Test-ValidString -Value $Value) {
        return
    }

    # Generate error message
    if (-not $ErrorMessage) {
        $paramText = if ($ParameterName) {
            "Parameter '$ParameterName': "
        }
        else {
            ''
        }

        $ErrorMessage = "${paramText}String value cannot be null or whitespace"
    }

    throw $ErrorMessage
}

# Export functions
Export-ModuleMember -Function @(
    'Test-ValidString',
    'Test-ValidPath',
    'Assert-ValidPath',
    'Assert-ValidString'
)
