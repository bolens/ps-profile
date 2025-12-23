<#
scripts/lib/ScoopDetection.psm1

.SYNOPSIS
    Scoop installation detection and path utilities.

.DESCRIPTION
    Provides functions for detecting Scoop installations, finding Scoop paths,
    and managing Scoop-related configuration. Handles multiple installation
    locations and cross-platform compatibility.

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
    Detects the Scoop installation root directory.

.DESCRIPTION
    Searches for Scoop installation in multiple locations:
    1. $env:SCOOP_GLOBAL environment variable (global installation, highest priority)
    2. $env:SCOOP environment variable (local installation)
    3. $env:USERPROFILE\scoop (Windows) or $env:HOME\scoop (Linux/macOS)
    
    Also checks for common package-specific environment variables that might
    point to Scoop installation directories.

.PARAMETER ErrorAction
    Action to take if Scoop is not found. Defaults to 'SilentlyContinue'.

.OUTPUTS
    System.String. Path to Scoop root directory, or $null if not found.

.EXAMPLE
    $scoopRoot = Get-ScoopRoot
    if ($scoopRoot) {
        Write-Host "Scoop found at: $scoopRoot"
    }
#>
function Get-ScoopRoot {
    [CmdletBinding()]
    [OutputType([string])]
    param()

    # Use Validation module if available
    $useValidation = Get-Command Test-ValidPath -ErrorAction SilentlyContinue

    # Check global Scoop installation first (highest priority)
    if ($env:SCOOP_GLOBAL) {
        $candidate = $env:SCOOP_GLOBAL
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

    # Check local Scoop installation
    if ($env:SCOOP) {
        $candidate = $env:SCOOP
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

    # Check for Scoop-related environment variables that might point to the root
    # Some packages or Scoop itself might set these
    $scoopEnvVars = @(
        'SCOOP_ROOT',
        'SCOOP_HOME'
    )
    
    foreach ($envVar in $scoopEnvVars) {
        if (Get-Variable -Name "env:$envVar" -ErrorAction SilentlyContinue) {
            $candidate = (Get-Variable -Name "env:$envVar" -ErrorAction SilentlyContinue).Value
            if ($candidate -and -not [string]::IsNullOrWhiteSpace($candidate)) {
                # If it points to a subdirectory, try to get the parent
                $testPath = $candidate
                if ((Test-Path -LiteralPath $testPath -PathType Container -ErrorAction SilentlyContinue)) {
                    # Check if this looks like a Scoop root (has apps, shims, etc.)
                    $appsPath = Join-Path $testPath 'apps'
                    if (Test-Path -LiteralPath $appsPath -PathType Container -ErrorAction SilentlyContinue) {
                        return $testPath
                    }
                    # Try parent directory
                    $parentPath = Split-Path -Parent $testPath
                    if ($parentPath -and (Test-Path -LiteralPath $parentPath -PathType Container -ErrorAction SilentlyContinue)) {
                        $appsPath = Join-Path $parentPath 'apps'
                        if (Test-Path -LiteralPath $appsPath -PathType Container -ErrorAction SilentlyContinue) {
                            return $parentPath
                        }
                    }
                }
            }
        }
    }

    # Check default user location (cross-platform compatible)
    $userHome = $null
    if ($env:HOME) {
        $userHome = $env:HOME
    }
    elseif ($env:USERPROFILE) {
        $userHome = $env:USERPROFILE
    }

    if ($userHome) {
        $defaultScoop = Join-Path $userHome 'scoop'
        $exists = if ($useValidation) {
            Test-ValidPath -Path $defaultScoop -PathType Directory
        }
        else {
            $defaultScoop -and -not [string]::IsNullOrWhiteSpace($defaultScoop) -and (Test-Path -LiteralPath $defaultScoop -PathType Container -ErrorAction SilentlyContinue)
        }
        if ($exists) {
            return $defaultScoop
        }
    }

    return $null
}

<#
.SYNOPSIS
    Gets the path to the Scoop completion module.

.DESCRIPTION
    Returns the path to Scoop-Completion.psd1 if it exists in the Scoop installation.

.PARAMETER ScoopRoot
    Optional. Path to Scoop root directory. If not provided, attempts to detect it.

.OUTPUTS
    System.String. Path to Scoop-Completion.psd1, or $null if not found.

.EXAMPLE
    $completionPath = Get-ScoopCompletionPath
    if ($completionPath) {
        Import-Module $completionPath
    }
#>
function Get-ScoopCompletionPath {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [string]$ScoopRoot
    )

    if (-not $ScoopRoot) {
        $ScoopRoot = Get-ScoopRoot
    }

    if (-not $ScoopRoot) {
        return $null
    }

    $completionPath = Join-Path $ScoopRoot 'apps' 'scoop' 'current' 'supporting' 'completion' 'Scoop-Completion.psd1'
    # Use Validation module if available
    if (Get-Command Test-ValidPath -ErrorAction SilentlyContinue) {
        if (Test-ValidPath -Path $completionPath -PathType File) {
            return $completionPath
        }
    }
    else {
        # Fallback to manual validation
        if ($completionPath -and -not [string]::IsNullOrWhiteSpace($completionPath) -and (Test-Path -LiteralPath $completionPath -PathType Leaf -ErrorAction SilentlyContinue)) {
            return $completionPath
        }
    }

    return $null
}

<#
.SYNOPSIS
    Gets the path to Scoop shims directory.

.DESCRIPTION
    Returns the path to the Scoop shims directory, which contains executable shims
    for Scoop-installed applications.

.PARAMETER ScoopRoot
    Optional. Path to Scoop root directory. If not provided, attempts to detect it.

.OUTPUTS
    System.String. Path to shims directory, or $null if not found.

.EXAMPLE
    $shimsPath = Get-ScoopShimsPath
    if ($shimsPath) {
        Write-Host "Shims at: $shimsPath"
    }
#>
function Get-ScoopShimsPath {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [string]$ScoopRoot
    )

    if (-not $ScoopRoot) {
        $ScoopRoot = Get-ScoopRoot
    }

    if (-not $ScoopRoot) {
        return $null
    }

    $shimsPath = Join-Path $ScoopRoot 'shims'
    # Use Validation module if available
    if (Get-Command Test-ValidPath -ErrorAction SilentlyContinue) {
        if (Test-ValidPath -Path $shimsPath -PathType Directory) {
            return $shimsPath
        }
    }
    else {
        # Fallback to manual validation
        if ($shimsPath -and -not [string]::IsNullOrWhiteSpace($shimsPath) -and (Test-Path -LiteralPath $shimsPath -PathType Container -ErrorAction SilentlyContinue)) {
            return $shimsPath
        }
    }

    return $null
}

<#
.SYNOPSIS
    Gets the path to Scoop bin directory.

.DESCRIPTION
    Returns the path to the Scoop bin directory, which contains additional
    Scoop utilities.

.PARAMETER ScoopRoot
    Optional. Path to Scoop root directory. If not provided, attempts to detect it.

.OUTPUTS
    System.String. Path to bin directory, or $null if not found.

.EXAMPLE
    $binPath = Get-ScoopBinPath
    if ($binPath) {
        Write-Host "Bin at: $binPath"
    }
#>
function Get-ScoopBinPath {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [string]$ScoopRoot
    )

    if (-not $ScoopRoot) {
        $ScoopRoot = Get-ScoopRoot
    }

    if (-not $ScoopRoot) {
        return $null
    }

    $binPath = Join-Path $ScoopRoot 'bin'
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
    Adds Scoop directories to the PATH environment variable.

.DESCRIPTION
    Adds Scoop shims and bin directories to the current session's PATH if they
    are not already present. Does not modify system/user PATH permanently.

.PARAMETER ScoopRoot
    Optional. Path to Scoop root directory. If not provided, attempts to detect it.

.PARAMETER AddShims
    If specified, adds the shims directory to PATH. Defaults to $true.

.PARAMETER AddBin
    If specified, adds the bin directory to PATH. Defaults to $true.

.OUTPUTS
    System.Boolean. $true if any paths were added, $false otherwise.

.EXAMPLE
    $added = Add-ScoopToPath
    if ($added) {
        Write-Host "Scoop paths added to PATH"
    }
#>
function Add-ScoopToPath {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [string]$ScoopRoot,
        [switch]$AddShims = $true,
        [switch]$AddBin = $true
    )

    if (-not $ScoopRoot) {
        $ScoopRoot = Get-ScoopRoot
    }

    if (-not $ScoopRoot) {
        return $false
    }

    $pathSeparator = [System.IO.Path]::PathSeparator
    $added = $false

    # Add shims directory
    if ($AddShims) {
        $shimsPath = Get-ScoopShimsPath -ScoopRoot $ScoopRoot
        if ($shimsPath -and $env:PATH -notlike "*$([regex]::Escape($shimsPath))*") {
            $env:PATH = "$shimsPath$pathSeparator$env:PATH"
            $added = $true
        }
    }

    # Add bin directory
    if ($AddBin) {
        $binPath = Get-ScoopBinPath -ScoopRoot $ScoopRoot
        if ($binPath -and $env:PATH -notlike "*$([regex]::Escape($binPath))*") {
            $env:PATH = "$binPath$pathSeparator$env:PATH"
            $added = $true
        }
    }

    return $added
}

<#
.SYNOPSIS
    Tests if Scoop is installed.

.DESCRIPTION
    Checks if Scoop is installed by attempting to detect the Scoop root directory.

.OUTPUTS
    System.Boolean. $true if Scoop is detected, $false otherwise.

.EXAMPLE
    if (Test-ScoopInstalled) {
        Write-Host "Scoop is installed"
    }
#>
function Test-ScoopInstalled {
    [CmdletBinding()]
    [OutputType([bool])]
    param()

    $scoopRoot = Get-ScoopRoot
    return ($null -ne $scoopRoot)
}

Export-ModuleMember -Function @(
    'Get-ScoopRoot',
    'Get-ScoopCompletionPath',
    'Get-ScoopShimsPath',
    'Get-ScoopBinPath',
    'Add-ScoopToPath',
    'Test-ScoopInstalled'
)

