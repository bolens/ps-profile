<#
scripts/lib/FileSystem.psm1

.SYNOPSIS
    File system operations and path validation utilities.

.DESCRIPTION
    Provides functions for directory creation, path validation, script file discovery,
    and other file system operations used across utility scripts.

.NOTES
    Module Version: 2.0.0
    PowerShell Version: 5.0+ (for enum support)
    
    This module now uses enums for type-safe path type handling.
    
    This module uses strict mode for enhanced error checking.
#>

# Enable strict mode for enhanced error checking
Set-StrictMode -Version Latest

# Import CommonEnums for FileSystemPathType enum
$commonEnumsPath = Join-Path (Split-Path -Parent $PSScriptRoot) 'core' 'CommonEnums.psm1'
if ($commonEnumsPath -and (Test-Path -LiteralPath $commonEnumsPath)) {
    Import-Module $commonEnumsPath -DisableNameChecking -ErrorAction SilentlyContinue
}

<#
.SYNOPSIS
    Ensures a directory exists, creating it if necessary.

.DESCRIPTION
    Checks if a directory exists, and creates it if it doesn't. Useful for
    ensuring output directories exist before writing files. Throws an error
    if directory creation fails.

.PARAMETER Path
    The directory path to ensure exists.

.PARAMETER ErrorMessage
    Custom error message to use if directory creation fails.

.EXAMPLE
    Ensure-DirectoryExists -Path (Join-Path $repoRoot 'scripts' 'data')
#>
function Ensure-DirectoryExists {
    [CmdletBinding()]
    [OutputType([void])]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Path,

        [string]$ErrorMessage
    )

    if (-not (Test-Path -Path $Path)) {
        try {
            New-Item -ItemType Directory -Path $Path -Force | Out-Null
            $debugLevel = 0
            if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel) -and $debugLevel -ge 2) {
                Write-Verbose "[filesystem.directory] Created directory: $Path"
            }
        }
        catch {
            if (-not $ErrorMessage) {
                $ErrorMessage = "Failed to create directory: $Path"
            }
            $debugLevel = 0
            if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel)) {
                if ($debugLevel -ge 1) {
                    if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                        Write-StructuredError -ErrorRecord $_ -OperationName 'filesystem.directory' -Context @{
                            Path         = $Path
                            ErrorMessage = $ErrorMessage
                        }
                    }
                    else {
                        Write-Error $ErrorMessage -ErrorAction Continue
                    }
                }
                # Level 3: Log detailed error information
                if ($debugLevel -ge 3) {
                    Write-Verbose "[filesystem.directory] Directory creation error details - Path: $Path, Exception: $($_.Exception.GetType().FullName), Message: $($_.Exception.Message), Stack: $($_.ScriptStackTrace)"
                }
            }
            else {
                # Always log critical errors even if debug is off
                if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                    Write-StructuredError -ErrorRecord $_ -OperationName 'filesystem.directory' -Context @{
                        Path         = $Path
                        ErrorMessage = $ErrorMessage
                    }
                }
                else {
                    Write-Error $ErrorMessage -ErrorAction Continue
                }
            }
            throw $ErrorMessage
        }
    }
    elseif (-not (Test-Path -Path $Path -PathType Container)) {
        if (-not $ErrorMessage) {
            $ErrorMessage = "Path exists but is not a directory: $Path"
        }
        throw $ErrorMessage
    }
}

<#
.SYNOPSIS
    Gets PowerShell script files from a directory.

.DESCRIPTION
    Retrieves PowerShell script files (.ps1) from the specified directory.
    Provides a consistent way to get script files across utility scripts.

.PARAMETER Path
    The directory path to search for PowerShell scripts.

.PARAMETER Recurse
    If specified, searches subdirectories recursively.

.PARAMETER SortByName
    If specified, sorts the results by name.

.OUTPUTS
    System.IO.FileInfo[]. Array of file information objects.

.EXAMPLE
    $scripts = Get-PowerShellScripts -Path $profileDir
    foreach ($script in $scripts) {
        Process-Script $script
    }
#>
function Get-PowerShellScripts {
    [CmdletBinding()]
    [OutputType([System.IO.FileInfo[]])]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Path,

        [switch]$Recurse,

        [switch]$SortByName
    )

    if (-not (Test-Path -Path $Path)) {
        throw "Path does not exist: $Path"
    }

    $params = @{
        Path   = $Path
        Filter = '*.ps1'
        File   = $true
    }

    if ($Recurse) {
        $params['Recurse'] = $true
    }

    try {
        $scripts = Get-ChildItem @params -ErrorAction Stop
    }
    catch [System.UnauthorizedAccessException] {
        $debugLevel = 0
        if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel)) {
            if ($debugLevel -ge 1) {
                if (Get-Command Write-StructuredWarning -ErrorAction SilentlyContinue) {
                    Write-StructuredWarning -Message "Access denied to some directories" -OperationName 'filesystem.get-scripts' -Context @{
                        path = $Path
                    } -Code 'AccessDenied'
                }
                else {
                    Write-Warning "[filesystem.get-scripts] Access denied to some directories in '$Path'. Results may be incomplete."
                }
            }
            # Level 3: Log detailed access denied information
            if ($debugLevel -ge 3) {
                Write-Host "  [filesystem.get-scripts] Access denied details - Path: $Path, Exception: $($_.Exception.GetType().FullName), Message: $($_.Exception.Message)" -ForegroundColor DarkGray
            }
        }
        else {
            # Always log warnings even if debug is off
            if (Get-Command Write-StructuredWarning -ErrorAction SilentlyContinue) {
                Write-StructuredWarning -Message "Access denied to some directories" -OperationName 'filesystem.get-scripts' -Context @{
                    path = $Path
                } -Code 'AccessDenied'
            }
            else {
                Write-Warning "[filesystem.get-scripts] Access denied to some directories in '$Path'. Results may be incomplete."
            }
        }
        # Try with ErrorAction SilentlyContinue to get partial results
        $scripts = Get-ChildItem @params -ErrorAction SilentlyContinue
    }
    catch {
        $errorMessage = "Failed to get PowerShell scripts from '$Path': $($_.Exception.Message)"
        $debugLevel = 0
        if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel)) {
            if ($debugLevel -ge 1) {
                if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                    Write-StructuredError -ErrorRecord $_ -OperationName 'filesystem.get-scripts' -Context @{
                        Path         = $Path
                        Recurse      = $Recurse
                        ErrorMessage = $errorMessage
                    }
                }
                else {
                    Write-Error $errorMessage -ErrorAction Continue
                }
            }
            # Level 3: Log detailed error information
            if ($debugLevel -ge 3) {
                Write-Host "  [filesystem.get-scripts] Get scripts error details - Path: $Path, Recurse: $Recurse, Exception: $($_.Exception.GetType().FullName), Message: $($_.Exception.Message), Stack: $($_.ScriptStackTrace)" -ForegroundColor DarkGray
            }
        }
        else {
            # Always log critical errors even if debug is off
            if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                Write-StructuredError -ErrorRecord $_ -OperationName 'filesystem.get-scripts' -Context @{
                    Path         = $Path
                    Recurse      = $Recurse
                    ErrorMessage = $errorMessage
                }
            }
            else {
                Write-Error $errorMessage -ErrorAction Continue
            }
        }
        throw $errorMessage
    }

    if ($SortByName) {
        $scripts = $scripts | Sort-Object Name
    }

    return $scripts
}

<#
.SYNOPSIS
    Tests if a path exists and throws an error if it doesn't.

.DESCRIPTION
    Validates that a file or directory path exists. Throws a descriptive error
    if the path is not found. Useful for parameter validation and early error detection.

.PARAMETER Path
    The path to test.

.PARAMETER PathType
    The type of path to validate. 'Any' (default), 'File', or 'Directory'.

.PARAMETER ErrorMessage
    Custom error message to use if path doesn't exist. If not provided, a default
    message is generated.

.EXAMPLE
    Test-PathExists -Path $configFile -PathType 'File'

.EXAMPLE
    Test-PathExists -Path $outputDir -PathType 'Directory' -ErrorMessage "Output directory not found"
#>
function Test-PathExists {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Path,

        [FileSystemPathType]$PathType = [FileSystemPathType]::Any,

        [string]$ErrorMessage
    )

    # Convert enum to string
    $pathTypeString = $PathType.ToString()
    
    if (-not (Test-Path -Path $Path)) {
        if (-not $ErrorMessage) {
            $typeLabel = switch ($pathTypeString) {
                'File' { 'file' }
                'Directory' { 'directory' }
                default { 'path' }
            }
            $ErrorMessage = "$typeLabel not found: $Path"
        }
        throw $ErrorMessage
    }

    if ($pathTypeString -eq 'File' -and -not (Test-Path -Path $Path -PathType Leaf)) {
        throw "Path exists but is not a file: $Path"
    }

    if ($pathTypeString -eq 'Directory' -and -not (Test-Path -Path $Path -PathType Container)) {
        throw "Path exists but is not a directory: $Path"
    }

    return $true
}

<#
.SYNOPSIS
    Validates that required parameters are not null or empty.

.DESCRIPTION
    Helper function to validate required parameters with consistent error messages.
    Throws an error if any parameter is null or empty.

.PARAMETER Parameters
    Hashtable of parameter names and values to validate.

.EXAMPLE
    Test-RequiredParameters -Parameters @{ Path = $Path; Name = $Name }
#>
function Test-RequiredParameters {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory)]
        [hashtable]$Parameters
    )

    foreach ($key in $Parameters.Keys) {
        $value = $Parameters[$key]
        if ($null -eq $value -or ($value -is [string] -and [string]::IsNullOrWhiteSpace($value))) {
            throw "Required parameter '$key' is null or empty."
        }
    }

    return $true
}

<#
.SYNOPSIS
    Creates a ValidateScript attribute for path parameters.

.DESCRIPTION
    Returns a scriptblock that can be used in ValidateScript attributes to validate
    that a path exists (if provided). If the path is null or empty, validation passes
    (for optional parameters). If a path is provided, it must exist.

.PARAMETER Path
    The path to validate. Accepts string or any type that can be converted to a string.
    Expected types: [string], [System.IO.FileInfo], [System.IO.DirectoryInfo], or any string-convertible type.

.PARAMETER PathType
    The type of path to validate. 'Any' (default), 'File', or 'Directory'.

.PARAMETER Optional
    If specified, allows null or empty values. Defaults to $true.

.EXAMPLE
    param(
        [ValidateScript({ Test-PathParameter -Path $_ -PathType 'File' -Optional })]
        [string]$ConfigFile
    )
#>
function Test-PathParameter {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory = $false)]
        [object]$Path,

        [FileSystemPathType]$PathType = [FileSystemPathType]::Any,

        [switch]$Optional
    )

    # Convert Path to string if it's not already (handles FileInfo, DirectoryInfo, etc.)
    $pathString = if ($Path -is [string]) {
        $Path
    }
    elseif ($null -ne $Path) {
        $Path.ToString()
    }
    else {
        $null
    }

    # Allow null/empty if optional
    if ($Optional -and ([string]::IsNullOrWhiteSpace($pathString))) {
        return $true
    }

    # Convert enum to string
    $pathTypeString = $PathType.ToString()
    
    # Validate path exists
    if (-not (Test-Path -Path $pathString)) {
        $typeLabel = switch ($pathTypeString) {
            'File' { 'file' }
            'Directory' { 'directory' }
            default { 'path' }
        }
        throw "$typeLabel does not exist: $pathString"
    }

    # Validate path type if specified
    if ($pathTypeString -eq 'File' -and -not (Test-Path -Path $pathString -PathType Leaf)) {
        throw "Path exists but is not a file: $pathString"
    }

    if ($pathTypeString -eq 'Directory' -and -not (Test-Path -Path $pathString -PathType Container)) {
        throw "Path exists but is not a directory: $pathString"
    }

    return $true
}

# Export functions
Export-ModuleMember -Function @(
    'Ensure-DirectoryExists',
    'Get-PowerShellScripts',
    'Test-PathExists',
    'Test-RequiredParameters',
    'Test-PathParameter'
)

