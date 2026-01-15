<#
scripts/lib/PathResolution.psm1

.SYNOPSIS
    Path resolution utilities.

.DESCRIPTION
    Provides functions for resolving repository paths and directory paths.

.NOTES
    This module uses strict mode for enhanced error checking.
#>

# Enable strict mode for enhanced error checking
Set-StrictMode -Version Latest

# Import SafeImport module if available for safer imports
# Note: We need to use manual check here since SafeImport itself uses Validation
$safeImportModulePath = Join-Path (Split-Path -Parent $PSScriptRoot) 'core' 'SafeImport.psm1'
if ($safeImportModulePath -and -not [string]::IsNullOrWhiteSpace($safeImportModulePath) -and (Test-Path -LiteralPath $safeImportModulePath)) {
    Import-Module $safeImportModulePath -DisableNameChecking -ErrorAction SilentlyContinue
}

# Import Cache module for caching support
$cacheModulePath = Join-Path $PSScriptRoot 'Cache.psm1'
if (Get-Command Import-ModuleSafely -ErrorAction SilentlyContinue) {
    # Import-ModuleSafely has ErrorAction as a parameter, don't pass it explicitly to avoid duplicate
    Import-ModuleSafely -ModulePath $cacheModulePath
}
else {
    # Fallback to manual validation
    if ($cacheModulePath -and -not [string]::IsNullOrWhiteSpace($cacheModulePath) -and (Test-Path -LiteralPath $cacheModulePath)) {
        Import-Module $cacheModulePath -ErrorAction SilentlyContinue
    }
}

# Import ErrorHandling module if available for consistent error action preference handling
$errorHandlingModulePath = Join-Path (Split-Path -Parent $PSScriptRoot) 'core' 'ErrorHandling.psm1'
if (Get-Command Import-ModuleSafely -ErrorAction SilentlyContinue) {
    # Import-ModuleSafely has ErrorAction as a parameter, don't pass it explicitly to avoid duplicate
    Import-ModuleSafely -ModulePath $errorHandlingModulePath -DisableNameChecking
}
else {
    # Fallback to manual validation
    if ($errorHandlingModulePath -and -not [string]::IsNullOrWhiteSpace($errorHandlingModulePath) -and (Test-Path -LiteralPath $errorHandlingModulePath)) {
        Import-Module $errorHandlingModulePath -DisableNameChecking -ErrorAction SilentlyContinue
    }
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
        [ValidateNotNullOrEmpty()]
        [string]$ScriptPath
    )

    # Cache repository root resolution (1 hour TTL since repository structure rarely changes)
    # Use CacheKey module if available for consistent key generation
    $cacheKey = if (Get-Command New-CacheKey -ErrorAction SilentlyContinue) {
        # New-CacheKey expects Components to be an array, wrap single string in array
        New-CacheKey -Prefix 'RepoRoot' -Components @($ScriptPath)
    }
    else {
        "RepoRoot_$ScriptPath"
    }
    if (Get-Command Get-CachedValue -ErrorAction SilentlyContinue) {
        $cachedResult = Get-CachedValue -Key $cacheKey
        if ($null -ne $cachedResult) {
            return $cachedResult
        }
    }

    # Normalize script path to absolute path (handles relative paths and ".." components)
    # Use Validation module if available
    $useValidation = Get-Command Test-ValidPath -ErrorAction SilentlyContinue
    
    $resolvedScriptPath = if ($useValidation) {
        if (Test-ValidPath -Path $ScriptPath -PathType File) {
            (Resolve-Path $ScriptPath).Path
        }
        else {
            $parentPath = Split-Path -Parent $ScriptPath
            if (Test-ValidPath -Path $parentPath -PathType Directory) {
                # File doesn't exist but parent directory does: construct absolute path from parent
                $parentDir = (Resolve-Path $parentPath).Path
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
        }
    }
    else {
        # Fallback to manual validation
        if ($ScriptPath -and -not [string]::IsNullOrWhiteSpace($ScriptPath) -and (Test-Path -LiteralPath $ScriptPath)) {
            (Resolve-Path $ScriptPath).Path
        }
        else {
            $parentPath = Split-Path -Parent $ScriptPath
            if ($parentPath -and -not [string]::IsNullOrWhiteSpace($parentPath) -and (Test-Path -LiteralPath $parentPath)) {
                # File doesn't exist but parent directory does: construct absolute path from parent
                $parentDir = (Resolve-Path $parentPath).Path
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

    if (-not $repoRoot -or -not ($repoRoot -and -not [string]::IsNullOrWhiteSpace($repoRoot) -and (Test-Path -LiteralPath $repoRoot))) {
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
        [ValidateNotNullOrEmpty()]
        [string]$ScriptPath
    )

    # Cache profile directory resolution (cache for 1 hour)
    # Use CacheKey module if available for consistent key generation
    $cacheKey = if (Get-Command New-CacheKey -ErrorAction SilentlyContinue) {
        # New-CacheKey expects Components to be an array, wrap single string in array
        New-CacheKey -Prefix 'ProfileDirectory' -Components @($ScriptPath)
    }
    else {
        "ProfileDirectory_$ScriptPath"
    }
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
        if (Get-Command Write-StructuredWarning -ErrorAction SilentlyContinue) {
            Write-StructuredWarning -Message "Could not determine repository root" -OperationName 'path-resolution.repo-root' -Context @{
                script_path = $PSScriptRoot
            } -Code 'RepositoryRootNotFound'
        }
        else {
            $debugLevel = 0
            if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel)) {
                if ($debugLevel -ge 1) {
                    if (Get-Command Write-StructuredWarning -ErrorAction SilentlyContinue) {
                        Write-StructuredWarning -Message "Could not determine repository root" -OperationName 'path-resolution.repo-root' -Context @{
                            script_path = $PSScriptRoot
                        } -Code 'RepositoryRootNotFound'
                    }
                    else {
                        Write-Warning "[path-resolution.repo-root] Could not determine repository root (script_path: $PSScriptRoot)"
                    }
                }
                # Level 3: Log detailed warning information
                if ($debugLevel -ge 3) {
                    Write-Host "  [path-resolution.repo-root] Repository root resolution warning details - ScriptPath: $PSScriptRoot, CurrentLocation: $((Get-Location).Path)" -ForegroundColor DarkGray
                }
            }
        }
    }
#>
function Get-RepoRootSafe {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$ScriptPath,

        [switch]$ExitOnError
    )

    # Get ErrorAction preference using ErrorHandling module if available
    if (Get-Command Get-ErrorActionPreference -ErrorAction SilentlyContinue) {
        $errorActionPreference = Get-ErrorActionPreference -PSBoundParameters $PSBoundParameters -Default 'Stop'
    }
    else {
        # Fallback to manual extraction
        $errorActionPreference = if ($PSBoundParameters.ContainsKey('ErrorAction')) {
            $PSBoundParameters['ErrorAction']
        }
        else {
            'Stop'
        }
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
                # ExitCodes module not available yet; surface a terminating error
                $debugLevel = 0
                if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel)) {
                    if ($debugLevel -ge 1) {
                        if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                            Write-StructuredError -ErrorRecord $_ -OperationName 'path-resolution.repo-root' -Context @{
                                script_path   = $ScriptPath
                                exit_on_error = $true
                            }
                        }
                        else {
                            Write-Error $errorMessage -ErrorAction Stop
                        }
                    }
                    # Level 3: Log detailed error information
                    if ($debugLevel -ge 3) {
                        Write-Host "  [path-resolution.repo-root] Exit on error details - ScriptPath: $ScriptPath, Exception: $($_.Exception.GetType().FullName), Message: $($_.Exception.Message), Stack: $($_.ScriptStackTrace)" -ForegroundColor DarkGray
                    }
                }
                else {
                    # Always log critical errors even if debug is off
                    if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                        Write-StructuredError -ErrorRecord $_ -OperationName 'path-resolution.repo-root' -Context @{
                            script_path   = $ScriptPath
                            exit_on_error = $true
                        }
                    }
                    else {
                        Write-Error $errorMessage -ErrorAction Stop
                    }
                }
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
                    $debugLevel = 0
                    if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel)) {
                        if ($debugLevel -ge 1) {
                            if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                                Write-StructuredError -ErrorRecord $_ -OperationName 'path-resolution.repo-root' -Context @{
                                    script_path  = $ScriptPath
                                    error_action = 'Continue'
                                }
                            }
                            else {
                                Write-Error $errorMessage -ErrorAction Continue
                            }
                        }
                        # Level 3: Log detailed error information
                        if ($debugLevel -ge 3) {
                            Write-Verbose "[path-resolution.repo-root] Continue error details - ScriptPath: $ScriptPath, Exception: $($_.Exception.GetType().FullName), Message: $($_.Exception.Message)"
                        }
                    }
                    else {
                        # Always log critical errors even if debug is off
                        if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                            Write-StructuredError -ErrorRecord $_ -OperationName 'path-resolution.repo-root' -Context @{
                                script_path  = $ScriptPath
                                error_action = 'Continue'
                            }
                        }
                        else {
                            Write-Error $errorMessage -ErrorAction Continue
                        }
                    }
                    return $null
                }
                default {
                    $debugLevel = 0
                    if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel)) {
                        if ($debugLevel -ge 1) {
                            if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                                Write-StructuredError -ErrorRecord $_ -OperationName 'path-resolution.repo-root' -Context @{
                                    script_path  = $ScriptPath
                                    error_action = $errorActionPreference
                                }
                            }
                            else {
                                Write-Error $errorMessage -ErrorAction $errorActionPreference
                            }
                        }
                        # Level 3: Log detailed error information
                        if ($debugLevel -ge 3) {
                            Write-Host "  [path-resolution.repo-root] Default error action details - ScriptPath: $ScriptPath, ErrorAction: $errorActionPreference, Exception: $($_.Exception.GetType().FullName), Message: $($_.Exception.Message)" -ForegroundColor DarkGray
                        }
                    }
                    else {
                        # Always log critical errors even if debug is off
                        if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                            Write-StructuredError -ErrorRecord $_ -OperationName 'path-resolution.repo-root' -Context @{
                                script_path  = $ScriptPath
                                error_action = $errorActionPreference
                            }
                        }
                        else {
                            Write-Error $errorMessage -ErrorAction $errorActionPreference
                        }
                    }
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
