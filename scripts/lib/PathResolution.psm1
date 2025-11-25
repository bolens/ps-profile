<#
scripts/lib/PathResolution.psm1

.SYNOPSIS
    Path resolution utilities.

.DESCRIPTION
    Provides functions for resolving repository paths and directory paths.
#>

# Import Cache module for caching support
$cacheModulePath = Join-Path $PSScriptRoot 'Cache.psm1'
if (Test-Path $cacheModulePath) {
    Import-Module $cacheModulePath -ErrorAction SilentlyContinue
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

    # Cache repository root resolution (1 hour TTL since repository structure rarely changes)
    $cacheKey = "RepoRoot_$ScriptPath"
    if (Get-Command Get-CachedValue -ErrorAction SilentlyContinue) {
        $cachedResult = Get-CachedValue -Key $cacheKey
        if ($null -ne $cachedResult) {
            return $cachedResult
        }
    }

    # Normalize script path to absolute path (handles relative paths and ".." components)
    $resolvedScriptPath = if (Test-Path $ScriptPath) {
        (Resolve-Path $ScriptPath).Path
    }
    elseif (Test-Path (Split-Path -Parent $ScriptPath)) {
        # File doesn't exist but parent directory does: construct absolute path from parent
        $parentDir = (Resolve-Path (Split-Path -Parent $ScriptPath)).Path
        Join-Path $parentDir (Split-Path -Leaf $ScriptPath)
    }
    else {
        # Fallback: make relative paths absolute using current location
        if (-not [System.IO.Path]::IsPathRooted($ScriptPath)) {
            Join-Path (Get-Location).Path $ScriptPath
        }
        else {
            $ScriptPath
        }
    }

    # Traverse up directory tree to find repository root (identified by presence of "scripts" directory)
    # Works from any scripts/ subdirectory: scripts/utils/, scripts/utils/code-quality/, scripts/checks/, etc.
    $currentDir = [System.IO.Path]::GetDirectoryName($resolvedScriptPath)
    $repoRoot = $null

    while ($currentDir -and $currentDir -ne [System.IO.Path]::GetDirectoryName($currentDir)) {
        $dirName = [System.IO.Path]::GetFileName($currentDir)
        if ($dirName -eq 'scripts') {
            # Found scripts directory: parent is repository root
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
    Gets the repository root directory path with built-in error handling.

.DESCRIPTION
    Wrapper around Get-RepoRoot that provides standardized error handling.
    Optionally exits the script with a proper exit code if the repository root
    cannot be found. This eliminates the need for repetitive try-catch blocks
    in utility scripts.

.PARAMETER ScriptPath
    Path to the script calling this function. Should be $PSScriptRoot from the calling script.

.PARAMETER ExitOnError
    If specified, exits the script with EXIT_SETUP_ERROR (2) if repository root cannot be found.
    Requires ExitCodes module to be imported. If ExitCodes is not available, throws instead.

.PARAMETER ErrorAction
    Action to take if repository root cannot be found. Defaults to 'Stop'.

.OUTPUTS
    System.String. The absolute path to the repository root directory.

.EXAMPLE
    $repoRoot = Get-RepoRootSafe -ScriptPath $PSScriptRoot

.EXAMPLE
    # Exit script on error (requires ExitCodes module)
    $repoRoot = Get-RepoRootSafe -ScriptPath $PSScriptRoot -ExitOnError

.EXAMPLE
    # Continue on error (returns $null)
    $repoRoot = Get-RepoRootSafe -ScriptPath $PSScriptRoot -ErrorAction SilentlyContinue
    if (-not $repoRoot) {
        Write-Warning "Could not determine repository root"
    }
#>
function Get-RepoRootSafe {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [string]$ScriptPath,

        [switch]$ExitOnError
    )

    # Get ErrorAction preference (from CmdletBinding common parameter)
    $errorActionPreference = if ($PSBoundParameters.ContainsKey('ErrorAction')) {
        $PSBoundParameters['ErrorAction']
    }
    else {
        'Stop'
    }

    try {
        return Get-RepoRoot -ScriptPath $ScriptPath
    }
    catch {
        $errorMessage = "Failed to resolve repository root: $($_.Exception.Message)"

        if ($ExitOnError) {
            # Try to use Exit-WithCode if ExitCodes module is available
            if (Get-Command Exit-WithCode -ErrorAction SilentlyContinue) {
                if (Get-Variable EXIT_SETUP_ERROR -ErrorAction SilentlyContinue) {
                    Exit-WithCode -ExitCode $EXIT_SETUP_ERROR -ErrorRecord $_
                }
                else {
                    Exit-WithCode -ExitCode 2 -ErrorRecord $_
                }
            }
            else {
                # ExitCodes module not available, throw instead
                Write-Error $errorMessage -ErrorAction Stop
                exit 2
            }
        }
        else {
            # Handle based on ErrorAction preference
            switch ($errorActionPreference) {
                'Stop' {
                    throw
                }
                'SilentlyContinue' {
                    return $null
                }
                'Continue' {
                    Write-Error $errorMessage -ErrorAction Continue
                    return $null
                }
                default {
                    Write-Error $errorMessage -ErrorAction $errorActionPreference
                    return $null
                }
            }
        }
    }
}

Export-ModuleMember -Function @(
    'Get-RepoRoot',
    'Get-ProfileDirectory',
    'Get-RepoRootSafe'
)

