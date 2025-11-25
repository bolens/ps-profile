<#
scripts/utils/code-quality/modules/OutputPathUtils.psm1

.SYNOPSIS
    Output path conversion utilities.

.DESCRIPTION
    Provides functions for converting absolute paths to repository-relative paths.
#>

# Script-level variables for repository root
$script:RepoRoot = $null
$script:RepoRootPattern = $null

<#
.SYNOPSIS
    Initializes output utilities with repository root information.

.DESCRIPTION
    Sets up the repository root pattern used for path sanitization.
    Must be called before using path conversion functions.

.PARAMETER RepoRoot
    The repository root directory path.
#>
function Initialize-OutputUtils {
    param(
        [string]$RepoRoot
    )

    $script:RepoRoot = $RepoRoot
    $script:RepoRootPattern = [regex]::Escape($RepoRoot.TrimEnd([System.IO.Path]::DirectorySeparatorChar, [System.IO.Path]::AltDirectorySeparatorChar))
}

<#
.SYNOPSIS
    Converts an arbitrary path to a repository-relative representation.

.DESCRIPTION
    Resolves the supplied path, and when it resides within the current repository
    root, returns the relative path. Paths outside the repository (or those that
    cannot be resolved) are returned unchanged.

.PARAMETER PathString
    The candidate path or text to convert.

.OUTPUTS
    System.String
#>
function ConvertTo-RepoRelativePath {
    param([string]$PathString)

    if ([string]::IsNullOrWhiteSpace($PathString)) {
        return $PathString
    }

    $candidate = $PathString
    try {
        $candidate = (Resolve-Path -Path $PathString -ErrorAction Stop).ProviderPath
    }
    catch {
        $candidate = $PathString
    }

    if (-not $script:RepoRoot) {
        return $candidate
    }

    # Check if the path is actually within the repository
    $normalizedRepoRoot = $script:RepoRoot.TrimEnd([System.IO.Path]::DirectorySeparatorChar, [System.IO.Path]::AltDirectorySeparatorChar)
    $normalizedCandidate = $candidate.TrimEnd([System.IO.Path]::DirectorySeparatorChar, [System.IO.Path]::AltDirectorySeparatorChar)

    if (-not $normalizedCandidate.StartsWith($normalizedRepoRoot, [StringComparison]::OrdinalIgnoreCase)) {
        # Path is outside repository, return original
        return $PathString
    }

    $relative = $candidate
    # Check if GetRelativePath is available (added in .NET Core 2.0)
    if ([System.IO.Path].GetMethods() | Where-Object { $_.Name -eq 'GetRelativePath' }) {
        $relative = [System.IO.Path]::GetRelativePath($script:RepoRoot, $candidate)
    }
    else {
        # Fallback for older .NET versions
        if ($candidate.StartsWith($script:RepoRoot, [StringComparison]::OrdinalIgnoreCase)) {
            $relative = $candidate.Substring($script:RepoRoot.Length).TrimStart([System.IO.Path]::DirectorySeparatorChar, [System.IO.Path]::AltDirectorySeparatorChar)
            if ([string]::IsNullOrEmpty($relative)) {
                $relative = "."
            }
        }
    }

    if (-not [System.IO.Path]::IsPathRooted($relative)) {
        return $relative
    }

    return $PathString
}

<#
.SYNOPSIS
    Gets the repository root pattern for sanitization.

.DESCRIPTION
    Returns the escaped repository root pattern used for output sanitization.
#>
function Get-RepoRootPattern {
    return $script:RepoRootPattern
}

Export-ModuleMember -Function @(
    'Initialize-OutputUtils',
    'ConvertTo-RepoRelativePath',
    'Get-RepoRootPattern'
)

