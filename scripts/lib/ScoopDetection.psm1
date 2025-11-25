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

# Import PathResolution for path operations
$pathModulePath = Join-Path $PSScriptRoot 'PathResolution.psm1'
if (Test-Path $pathModulePath) {
    Import-Module $pathModulePath -ErrorAction SilentlyContinue
}

# Import Platform for platform detection
$platformModulePath = Join-Path $PSScriptRoot 'Platform.psm1'
if (Test-Path $platformModulePath) {
    Import-Module $platformModulePath -ErrorAction SilentlyContinue
}

<#
.SYNOPSIS
    Detects the Scoop installation root directory.

.DESCRIPTION
    Searches for Scoop installation in multiple locations:
    1. $env:SCOOP environment variable
    2. $env:USERPROFILE\scoop (Windows) or $env:HOME\scoop (Linux/macOS)

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

    # Check global Scoop installation first (highest priority)
    if ($env:SCOOP_GLOBAL) {
        $candidate = $env:SCOOP_GLOBAL
        if (Test-Path $candidate -PathType Container -ErrorAction SilentlyContinue) {
            return $candidate
        }
    }

    # Check local Scoop installation
    if ($env:SCOOP) {
        $candidate = $env:SCOOP
        if (Test-Path $candidate -PathType Container -ErrorAction SilentlyContinue) {
            return $candidate
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
        if (Test-Path $defaultScoop -PathType Container -ErrorAction SilentlyContinue) {
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
    if (Test-Path $completionPath -PathType Leaf -ErrorAction SilentlyContinue) {
        return $completionPath
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
    if (Test-Path $shimsPath -PathType Container -ErrorAction SilentlyContinue) {
        return $shimsPath
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
    if (Test-Path $binPath -PathType Container -ErrorAction SilentlyContinue) {
        return $binPath
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

