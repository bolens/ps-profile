<#
scripts/lib/Path.psm1

.SYNOPSIS
    Path resolution and repository utilities.

.DESCRIPTION
    Provides functions for resolving repository paths, module paths, and other
    path-related utilities used across utility scripts.

.NOTES
    Module Version: 1.0.0
    PowerShell Version: 3.0+
#>

# Import Cache module for caching support
$cacheModulePath = Join-Path $PSScriptRoot 'Cache.psm1'
if (Test-Path $cacheModulePath) {
    Import-Module $cacheModulePath -ErrorAction SilentlyContinue
}

<#
.SYNOPSIS
    Gets the path to the Common.psm1 module file.

.DESCRIPTION
    Returns the absolute path to Common.psm1 based on the calling script's location.
    This provides a consistent way to import Common.psm1 from any script location.

.PARAMETER ScriptPath
    Path to the script calling this function. Should be $PSScriptRoot from the calling script.

.OUTPUTS
    System.String. The absolute path to Common.psm1.

.EXAMPLE
    $commonPath = Get-CommonModulePath -ScriptPath $PSScriptRoot
    Import-Module $commonPath -ErrorAction Stop
#>
function Get-CommonModulePath {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [string]$ScriptPath
    )

    # Resolve provided path to handle relative input and determine whether it is a directory or file
    $resolvedPath = if (Test-Path $ScriptPath) {
        (Resolve-Path $ScriptPath).Path
    }
    else {
        $ScriptPath
    }

    $scriptDir = if (Test-Path $resolvedPath -PathType Container) {
        $resolvedPath
    }
    else {
        Split-Path -Parent $resolvedPath
    }

    # Check if we're in scripts/utils/, scripts/checks/, scripts/git/, scripts/lib/, etc.
    if ($scriptDir -match 'scripts[\\/](utils|checks|git|lib|dev|templates|examples)$') {
        # If in scripts/lib/, Common.psm1 is in the same directory
        if ($scriptDir -match 'scripts[\\/]lib$') {
            $commonPath = Join-Path $scriptDir 'Common.psm1'
        }
        else {
            # If in other scripts subdirectories, Common.psm1 is in scripts/lib/
            $scriptsDir = Split-Path -Parent $scriptDir
            $commonPath = Join-Path $scriptsDir 'lib' 'Common.psm1'
        }
    }
    else {
        try {
            $repoRoot = Get-RepoRoot -ScriptPath $scriptDir
            $commonPath = Join-Path $repoRoot 'scripts' 'lib' 'Common.psm1'
        }
        catch {
            # Fallback: climb parents until we find a scripts directory
            $current = $scriptDir
            $found = $false
            while ($current -and -not $found) {
                if (Test-Path (Join-Path $current 'scripts')) {
                    $commonPath = Join-Path $current 'scripts' 'lib' 'Common.psm1'
                    $found = $true
                }
                else {
                    $parent = Split-Path -Parent $current
                    if ($parent -eq $current) { break }
                    $current = $parent
                }
            }

            if (-not $found) {
                $commonPath = Join-Path $scriptDir 'scripts' 'lib' 'Common.psm1'
            }
        }
    }

    if (-not (Test-Path $commonPath)) {
        throw "Common.psm1 not found at: $commonPath. Ensure the script is located in a scripts/ subdirectory."
    }

    return (Resolve-Path $commonPath).Path
}

<#
.SYNOPSIS
    Gets the repository root directory path.

.DESCRIPTION
    Calculates the repository root directory path relative to the calling script.
    Works with scripts in any scripts/ subdirectory (e.g., scripts/utils/, scripts/utils/code-quality/, scripts/checks/, scripts/git/).
    Scripts should pass their own $PSScriptRoot when calling this function.

.PARAMETER ScriptPath
    Path to the script calling this function. Should be $PSScriptRoot from the calling script.

.OUTPUTS
    System.String. The absolute path to the repository root directory.

.EXAMPLE
    $repoRoot = Get-RepoRoot -ScriptPath $PSScriptRoot
    $profileDir = Join-Path $repoRoot 'profile.d'
#>
function Get-RepoRoot {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [string]$ScriptPath
    )

    # Cache repo root resolution (cache for 1 hour since it rarely changes)
    $cacheKey = "RepoRoot_$ScriptPath"
    if (Get-Command Get-CachedValue -ErrorAction SilentlyContinue) {
        $cachedResult = Get-CachedValue -Key $cacheKey
        if ($null -ne $cachedResult) {
            return $cachedResult
        }
    }

    # Resolve the script path first to handle relative paths and ".."
    # Convert to absolute path for reliable processing
    $resolvedScriptPath = if (Test-Path $ScriptPath) {
        (Resolve-Path $ScriptPath).Path
    }
    elseif (Test-Path (Split-Path -Parent $ScriptPath)) {
        # If file doesn't exist but parent does, construct absolute path
        $parentDir = (Resolve-Path (Split-Path -Parent $ScriptPath)).Path
        Join-Path $parentDir (Split-Path -Leaf $ScriptPath)
    }
    else {
        # Fallback: try to make it absolute relative to current location
        if (-not [System.IO.Path]::IsPathRooted($ScriptPath)) {
            Join-Path (Get-Location).Path $ScriptPath
        }
        else {
            $ScriptPath
        }
    }

    # Find repository root by looking for scripts/ directory
    # Scripts can be in scripts/utils/, scripts/utils/code-quality/, scripts/checks/, scripts/git/, etc.
    # Go up from script directory until we find a directory named "scripts"
    $currentDir = [System.IO.Path]::GetDirectoryName($resolvedScriptPath)
    $repoRoot = $null

    while ($currentDir -and $currentDir -ne [System.IO.Path]::GetDirectoryName($currentDir)) {
        $dirName = [System.IO.Path]::GetFileName($currentDir)
        if ($dirName -eq 'scripts') {
            $repoRoot = [System.IO.Path]::GetDirectoryName($currentDir)
            break
        }
        $currentDir = [System.IO.Path]::GetDirectoryName($currentDir)
    }

    if (-not $repoRoot -or -not (Test-Path $repoRoot)) {
        throw "Repository root not found. Ensure the script is located in a scripts/ subdirectory."
    }

    # Resolve and normalize the path
    $resolvedRepoRoot = (Resolve-Path $repoRoot).Path

    # Cache the result
    if (Get-Command Set-CachedValue -ErrorAction SilentlyContinue) {
        Set-CachedValue -Key $cacheKey -Value $resolvedRepoRoot -ExpirationSeconds 3600
    }
    return $resolvedRepoRoot
}

<#
.SYNOPSIS
    Gets the profile.d directory path.

.DESCRIPTION
    Returns the path to the profile.d directory relative to the repository root.
    This is a convenience function to avoid repeating the Join-Path pattern.

.PARAMETER ScriptPath
    Path to the script calling this function. Should be $PSScriptRoot from the calling script.

.OUTPUTS
    System.String. The absolute path to the profile.d directory.

.EXAMPLE
    $profileDir = Get-ProfileDirectory -ScriptPath $PSScriptRoot
    $fragments = Get-ChildItem -Path $profileDir -Filter '*.ps1'
#>
function Get-ProfileDirectory {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [string]$ScriptPath
    )

    # Cache profile directory resolution (cache for 1 hour)
    $cacheKey = "ProfileDirectory_$ScriptPath"
    if (Get-Command Get-CachedValue -ErrorAction SilentlyContinue) {
        $cachedResult = Get-CachedValue -Key $cacheKey
        if ($null -ne $cachedResult) {
            return $cachedResult
        }
    }

    $repoRoot = Get-RepoRoot -ScriptPath $ScriptPath
    $profileDir = Join-Path $repoRoot 'profile.d'

    # Cache the result
    if (Get-Command Set-CachedValue -ErrorAction SilentlyContinue) {
        Set-CachedValue -Key $cacheKey -Value $profileDir -ExpirationSeconds 3600
    }
    return $profileDir
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
    }
    return $Path
}

<#
.SYNOPSIS
    Gets the appropriate PowerShell executable name for the current environment.

.DESCRIPTION
    Returns 'pwsh' for PowerShell Core or 'powershell' for Windows PowerShell.
    Useful for scripts that need to spawn PowerShell processes.

.OUTPUTS
    System.String. The PowerShell executable name ('pwsh' or 'powershell').

.EXAMPLE
    $psExe = Get-PowerShellExecutable
    & $psExe -NoProfile -File $scriptPath
#>
function Get-PowerShellExecutable {
    [CmdletBinding()]
    [OutputType([string])]
    param()

    if ($PSVersionTable.PSEdition -eq 'Core') {
        return 'pwsh'
    }
    else {
        return 'powershell'
    }
}

# Export functions
Export-ModuleMember -Function @(
    'Get-CommonModulePath',
    'Get-RepoRoot',
    'Get-ProfileDirectory',
    'Resolve-DefaultPath',
    'Get-PowerShellExecutable'
)

