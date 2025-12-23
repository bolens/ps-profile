<#
scripts/lib/runtime/ChocolateyDetection.psm1

.SYNOPSIS
    Chocolatey installation detection and path utilities.

.DESCRIPTION
    Provides functions for detecting Chocolatey installations, finding Chocolatey paths,
    and managing Chocolatey-related configuration. Handles multiple installation
    locations and Windows-specific paths.

.NOTES
    Module Version: 1.0.0
    PowerShell Version: 3.0+
    Chocolatey is Windows-only, so this module is Windows-specific.
#>

# Import SafeImport module if available for safer imports
# Note: We need to use manual check here since SafeImport itself uses Validation
$safeImportModulePath = Join-Path (Split-Path -Parent $PSScriptRoot) 'core' 'SafeImport.psm1'
if ($safeImportModulePath -and -not [string]::IsNullOrWhiteSpace($safeImportModulePath) -and (Test-Path -LiteralPath $safeImportModulePath)) {
    Import-Module $safeImportModulePath -DisableNameChecking -ErrorAction SilentlyContinue
}

# Import PathResolution for path operations
$pathModulePath = Join-Path $PSScriptRoot 'PathResolution.psm1'
if (Get-Command Import-ModuleSafely -ErrorAction SilentlyContinue) {
    Import-ModuleSafely -ModulePath $pathModulePath -ErrorAction SilentlyContinue
}
else {
    # Fallback to manual validation
    if ($pathModulePath -and -not [string]::IsNullOrWhiteSpace($pathModulePath) -and (Test-Path -LiteralPath $pathModulePath)) {
        Import-Module $pathModulePath -ErrorAction SilentlyContinue
    }
}

# Import Platform for platform detection
$platformModulePath = Join-Path $PSScriptRoot 'Platform.psm1'
if (Get-Command Import-ModuleSafely -ErrorAction SilentlyContinue) {
    Import-ModuleSafely -ModulePath $platformModulePath -ErrorAction SilentlyContinue
}
else {
    # Fallback to manual validation
    if ($platformModulePath -and -not [string]::IsNullOrWhiteSpace($platformModulePath) -and (Test-Path -LiteralPath $platformModulePath)) {
        Import-Module $platformModulePath -ErrorAction SilentlyContinue
    }
}

<#
.SYNOPSIS
    Detects the Chocolatey installation root directory.

.DESCRIPTION
    Searches for Chocolatey installation in multiple locations:
    1. $env:ChocolateyInstall environment variable (highest priority)
    2. $env:ProgramData\chocolatey (default installation location)
    3. C:\ProgramData\chocolatey (fallback)
    
    Also checks for common package-specific environment variables that might
    point to Chocolatey installation directories.

.PARAMETER ErrorAction
    Action to take if Chocolatey is not found. Defaults to 'SilentlyContinue'.

.OUTPUTS
    System.String. Path to Chocolatey root directory, or $null if not found.

.EXAMPLE
    $chocoRoot = Get-ChocolateyRoot
    if ($chocoRoot) {
        Write-Host "Chocolatey found at: $chocoRoot"
    }
#>
function Get-ChocolateyRoot {
    [CmdletBinding()]
    [OutputType([string])]
    param()

    # Use Validation module if available
    $useValidation = Get-Command Test-ValidPath -ErrorAction SilentlyContinue

    # Check ChocolateyInstall environment variable first (highest priority)
    if ($env:ChocolateyInstall) {
        $candidate = $env:ChocolateyInstall
        $exists = if ($useValidation) {
            Test-ValidPath -Path $candidate -PathType Directory
        }
        else {
            $candidate -and -not [string]::IsNullOrWhiteSpace($candidate) -and (Test-Path -LiteralPath $candidate -PathType Container -ErrorAction SilentlyContinue)
        }
        if ($exists) {
            return $candidate
        }
    }

    # Check for Chocolatey-related environment variables that might point to the root
    # Some packages or Chocolatey itself might set these
    $chocoEnvVars = @(
        'ChocolateyPath',
        'ChocolateyToolsLocation',
        'ChocolateyBinRoot'
    )
    
    foreach ($envVar in $chocoEnvVars) {
        if (Get-Variable -Name "env:$envVar" -ErrorAction SilentlyContinue) {
            $candidate = (Get-Variable -Name "env:$envVar" -ErrorAction SilentlyContinue).Value
            if ($candidate -and -not [string]::IsNullOrWhiteSpace($candidate)) {
                # If it points to a subdirectory, try to get the parent
                $testPath = $candidate
                if ((Test-Path -LiteralPath $testPath -PathType Container -ErrorAction SilentlyContinue)) {
                    # Check if this looks like a Chocolatey root (has lib, bin, etc.)
                    $libPath = Join-Path $testPath 'lib'
                    if (Test-Path -LiteralPath $libPath -PathType Container -ErrorAction SilentlyContinue) {
                        return $testPath
                    }
                    # Try parent directory
                    $parentPath = Split-Path -Parent $testPath
                    if ($parentPath -and (Test-Path -LiteralPath $parentPath -PathType Container -ErrorAction SilentlyContinue)) {
                        $libPath = Join-Path $parentPath 'lib'
                        if (Test-Path -LiteralPath $libPath -PathType Container -ErrorAction SilentlyContinue) {
                            return $parentPath
                        }
                    }
                }
            }
        }
    }

    # Check default installation location (ProgramData)
    if ($env:ProgramData) {
        $defaultChoco = Join-Path $env:ProgramData 'chocolatey'
        $exists = if ($useValidation) {
            Test-ValidPath -Path $defaultChoco -PathType Directory
        }
        else {
            $defaultChoco -and -not [string]::IsNullOrWhiteSpace($defaultChoco) -and (Test-Path -LiteralPath $defaultChoco -PathType Container -ErrorAction SilentlyContinue)
        }
        if ($exists) {
            return $defaultChoco
        }
    }

    # Fallback to hardcoded default path (Windows only)
    $fallbackChoco = 'C:\ProgramData\chocolatey'
    $exists = if ($useValidation) {
        Test-ValidPath -Path $fallbackChoco -PathType Directory
    }
    else {
        $fallbackChoco -and -not [string]::IsNullOrWhiteSpace($fallbackChoco) -and (Test-Path -LiteralPath $fallbackChoco -PathType Container -ErrorAction SilentlyContinue)
    }
    if ($exists) {
        return $fallbackChoco
    }

    return $null
}

<#
.SYNOPSIS
    Gets the path to the Chocolatey lib directory.

.DESCRIPTION
    Returns the path to the Chocolatey lib directory, which contains installed packages.

.PARAMETER ChocolateyRoot
    Optional. Path to Chocolatey root directory. If not provided, attempts to detect it.

.OUTPUTS
    System.String. Path to lib directory, or $null if not found.

.EXAMPLE
    $libPath = Get-ChocolateyLibPath
    if ($libPath) {
        Write-Host "Packages at: $libPath"
    }
#>
function Get-ChocolateyLibPath {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [string]$ChocolateyRoot
    )

    if (-not $ChocolateyRoot) {
        $ChocolateyRoot = Get-ChocolateyRoot
    }

    if (-not $ChocolateyRoot) {
        return $null
    }

    $libPath = Join-Path $ChocolateyRoot 'lib'
    # Use Validation module if available
    if (Get-Command Test-ValidPath -ErrorAction SilentlyContinue) {
        if (Test-ValidPath -Path $libPath -PathType Directory) {
            return $libPath
        }
    }
    else {
        # Fallback to manual validation
        if ($libPath -and -not [string]::IsNullOrWhiteSpace($libPath) -and (Test-Path -LiteralPath $libPath -PathType Container -ErrorAction SilentlyContinue)) {
            return $libPath
        }
    }

    return $null
}

<#
.SYNOPSIS
    Gets the path to Chocolatey bin directory.

.DESCRIPTION
    Returns the path to the Chocolatey bin directory, which contains Chocolatey executables
    and package binaries.

.PARAMETER ChocolateyRoot
    Optional. Path to Chocolatey root directory. If not provided, attempts to detect it.

.OUTPUTS
    System.String. Path to bin directory, or $null if not found.

.EXAMPLE
    $binPath = Get-ChocolateyBinPath
    if ($binPath) {
        Write-Host "Binaries at: $binPath"
    }
#>
function Get-ChocolateyBinPath {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [string]$ChocolateyRoot
    )

    if (-not $ChocolateyRoot) {
        $ChocolateyRoot = Get-ChocolateyRoot
    }

    if (-not $ChocolateyRoot) {
        return $null
    }

    $binPath = Join-Path $ChocolateyRoot 'bin'
    # Use Validation module if available
    if (Get-Command Test-ValidPath -ErrorAction SilentlyContinue) {
        if (Test-ValidPath -Path $binPath -PathType Directory) {
            return $binPath
        }
    }
    else {
        # Fallback to manual validation
        if ($binPath -and -not [string]::IsNullOrWhiteSpace($binPath) -and (Test-Path -LiteralPath $binPath -PathType Container -ErrorAction SilentlyContinue)) {
            return $binPath
        }
    }

    return $null
}

<#
.SYNOPSIS
    Tests if Chocolatey is installed.

.DESCRIPTION
    Checks if Chocolatey is installed by attempting to detect the Chocolatey root directory
    and optionally checking for the choco command.

.PARAMETER CheckCommand
    If specified, also checks if the 'choco' command is available in PATH.

.OUTPUTS
    System.Boolean. $true if Chocolatey is detected, $false otherwise.

.EXAMPLE
    if (Test-ChocolateyInstalled) {
        Write-Host "Chocolatey is installed"
    }

.EXAMPLE
    if (Test-ChocolateyInstalled -CheckCommand) {
        Write-Host "Chocolatey is installed and choco command is available"
    }
#>
function Test-ChocolateyInstalled {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [switch]$CheckCommand
    )

    $chocoRoot = Get-ChocolateyRoot
    if (-not $chocoRoot) {
        return $false
    }

    # If CheckCommand is specified, also verify choco command is available
    if ($CheckCommand) {
        if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
            return $false
        }
    }

    return $true
}

Export-ModuleMember -Function @(
    'Get-ChocolateyRoot',
    'Get-ChocolateyLibPath',
    'Get-ChocolateyBinPath',
    'Test-ChocolateyInstalled'
)

