<#
scripts/lib/core/SafeImport.psm1

.SYNOPSIS
    Safe module import utilities with validation.

.DESCRIPTION
    Provides functions for safely importing PowerShell modules with path validation
    and error handling. Reduces boilerplate code for the common pattern of checking
    if a module path exists before importing.

.NOTES
    Module Version: 1.0.0
    PowerShell Version: 3.0+
#>

# Import Validation module for path validation
$validationModulePath = Join-Path $PSScriptRoot 'Validation.psm1'
if ($validationModulePath -and -not [string]::IsNullOrWhiteSpace($validationModulePath) -and (Test-Path -LiteralPath $validationModulePath)) {
    Import-Module $validationModulePath -DisableNameChecking -ErrorAction SilentlyContinue
}

<#
.SYNOPSIS
    Tests if a module path is valid and can be imported.

.DESCRIPTION
    Validates that a module path exists and is a valid PowerShell module file.
    This is a common pattern used before importing modules.

.PARAMETER ModulePath
    The path to the module file to validate.

.OUTPUTS
    System.Boolean. Returns $true if the module path is valid, $false otherwise.

.EXAMPLE
    if (Test-ModulePath -ModulePath $modulePath) {
        Import-Module $modulePath
    }
#>
function Test-ModulePath {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory)]
        [AllowNull()]
        [object]$ModulePath
    )

    # Use Validation module if available
    if (Get-Command Test-ValidPath -ErrorAction SilentlyContinue) {
        return Test-ValidPath -Path $ModulePath -PathType File
    }

    # Fallback to manual validation
    if ($null -eq $ModulePath) {
        return $false
    }

    $pathString = if ($ModulePath -is [string]) {
        $ModulePath
    }
    else {
        $ModulePath.ToString()
    }

    if ([string]::IsNullOrWhiteSpace($pathString)) {
        return $false
    }

    return (Test-Path -LiteralPath $pathString -PathType Leaf -ErrorAction SilentlyContinue)
}

<#
.SYNOPSIS
    Safely imports a PowerShell module with path validation.

.DESCRIPTION
    Validates the module path exists before attempting to import. Provides
    consistent error handling and import parameters. This reduces the common
    boilerplate pattern of checking path validity before importing.

.PARAMETER ModulePath
    The path to the module file to import.

.PARAMETER DisableNameChecking
    If specified, disables name checking during import.

.PARAMETER Global
    If specified, imports the module into the global scope.

.PARAMETER ErrorAction
    Action to take if import fails. Defaults to SilentlyContinue for safe imports.
    Use 'Stop' if the module is required.

.PARAMETER Required
    If specified, throws an error if the module path is invalid or import fails.
    Defaults to $false for safe imports.

.OUTPUTS
    System.Management.Automation.PSModuleInfo. The imported module, or $null if
    import failed and Required is $false.

.EXAMPLE
    $module = Import-ModuleSafely -ModulePath $modulePath -DisableNameChecking

.EXAMPLE
    # Required module - throws if not found
    Import-ModuleSafely -ModulePath $requiredModule -Required -ErrorAction Stop

.EXAMPLE
    # Optional module - returns $null if not found
    $module = Import-ModuleSafely -ModulePath $optionalModule -ErrorAction SilentlyContinue
#>
function Import-ModuleSafely {
    [CmdletBinding()]
    [OutputType([System.Management.Automation.PSModuleInfo])]
    param(
        [Parameter(Mandatory)]
        [AllowNull()]
        [object]$ModulePath,

        [switch]$DisableNameChecking,

        [switch]$Global,

        # Note: ErrorAction is provided by [CmdletBinding()] as a common parameter
        # We use $PSBoundParameters to check if it was explicitly provided, otherwise default to SilentlyContinue

        [bool]$Required = $false
    )

    # Get ErrorAction from common parameters (provided by [CmdletBinding()])
    $errorAction = if ($PSBoundParameters.ContainsKey('ErrorAction')) {
        $PSBoundParameters['ErrorAction']
    }
    else {
        'SilentlyContinue'
    }

    # Validate module path
    if (-not (Test-ModulePath -ModulePath $ModulePath)) {
        if ($Required) {
            $pathString = if ($ModulePath -is [string]) {
                $ModulePath
            }
            elseif ($null -ne $ModulePath) {
                $ModulePath.ToString()
            }
            else {
                'null'
            }
            throw "Module path is invalid or does not exist: $pathString"
        }
        return $null
    }

    # Convert to string path
    $pathString = if ($ModulePath -is [string]) {
        $ModulePath
    }
    else {
        $ModulePath.ToString()
    }

    # Import module with specified parameters
    try {
        $importParams = @{
            ErrorAction = $errorAction
            PassThru    = $true
        }

        if ($DisableNameChecking) {
            $importParams['DisableNameChecking'] = $true
        }

        if ($Global) {
            $importParams['Global'] = $true
        }

        # Import-Module doesn't support -LiteralPath, use -Name with resolved path or pass path directly
        $importedModule = Import-Module $pathString @importParams
        return $importedModule
    }
    catch {
        if ($Required -or $errorAction -eq 'Stop') {
            throw "Failed to import module from '$pathString': $($_.Exception.Message)"
        }
        return $null
    }
}

<#
.SYNOPSIS
    Gets and validates a module path, resolving relative paths if needed.

.DESCRIPTION
    Resolves a module path (relative or absolute) and validates it exists.
    Useful for constructing module paths before importing.

.PARAMETER ModulePath
    The module path to resolve and validate. Can be relative or absolute.

.PARAMETER BasePath
    Optional base path for resolving relative module paths. If not specified,
    uses the current location.

.PARAMETER MustExist
    If specified, the path must exist. Defaults to $true.

.OUTPUTS
    System.String. The resolved and validated module path, or $null if invalid
    and MustExist is $false.

.EXAMPLE
    $modulePath = Get-ModulePath -ModulePath 'core\Logging.psm1' -BasePath $libDir

.EXAMPLE
    $modulePath = Get-ModulePath -ModulePath $relativePath -MustExist:$false
#>
function Get-ModulePath {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [AllowNull()]
        [object]$ModulePath,

        [string]$BasePath,

        [bool]$MustExist = $true
    )

    if ($null -eq $ModulePath) {
        return $null
    }

    $pathString = if ($ModulePath -is [string]) {
        $ModulePath
    }
    else {
        $ModulePath.ToString()
    }

    if ([string]::IsNullOrWhiteSpace($pathString)) {
        return $null
    }

    # Resolve path
    $resolvedPath = if ($BasePath) {
        Join-Path $BasePath $pathString
    }
    elseif ([System.IO.Path]::IsPathRooted($pathString)) {
        $pathString
    }
    else {
        Join-Path (Get-Location).Path $pathString
    }

    # Normalize path
    try {
        $resolvedPath = [System.IO.Path]::GetFullPath($resolvedPath)
    }
    catch {
        return $null
    }

    # Validate if required
    if ($MustExist) {
        if (-not (Test-ModulePath -ModulePath $resolvedPath)) {
            return $null
        }
    }

    return $resolvedPath
}

# Export functions
Export-ModuleMember -Function @(
    'Test-ModulePath',
    'Import-ModuleSafely',
    'Get-ModulePath'
)

