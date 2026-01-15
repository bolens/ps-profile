<#
scripts/lib/PathUtilities.psm1

.SYNOPSIS
    Path manipulation utilities.

.DESCRIPTION
    Provides functions for calculating relative paths, normalizing paths, and other
    common path manipulation operations. Centralizes path calculation logic that is
    duplicated across multiple scripts.

.NOTES
    Module Version: 1.0.0
    PowerShell Version: 3.0+
    
    This module uses strict mode for enhanced error checking.
#>

# Enable strict mode for enhanced error checking
Set-StrictMode -Version Latest

<#
.SYNOPSIS
    Calculates a relative path from one path to another.

.DESCRIPTION
    Calculates the relative path from a base path to a target path. Uses .NET's
    Path.GetRelativePath when available, with fallback to URI-based calculation for
    older .NET versions.

.PARAMETER From
    The base path (source directory).

.PARAMETER To
    The target path (file or directory).

.OUTPUTS
    System.String. The relative path from From to To.

.EXAMPLE
    $relative = Get-RelativePath -From "C:\repo\scripts" -To "C:\repo\scripts\utils\script.ps1"
    # Returns: utils\script.ps1

.EXAMPLE
    $relative = Get-RelativePath -From $repoRoot -To $scriptPath
    # Returns: scripts\utils\script.ps1
#>
function Get-RelativePath {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$From,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$To
    )

    # Normalize paths
    $fromPath = $From.TrimEnd([System.IO.Path]::DirectorySeparatorChar, [System.IO.Path]::AltDirectorySeparatorChar)
    $toPath = $To.TrimEnd([System.IO.Path]::DirectorySeparatorChar, [System.IO.Path]::AltDirectorySeparatorChar)

    # Try to resolve paths if they exist
    # Use Validation module if available
    $useValidation = Get-Command Test-ValidPath -ErrorAction SilentlyContinue
    
    try {
        if ($useValidation) {
            if (Test-ValidPath -Path $fromPath) {
                $fromPath = (Resolve-Path $fromPath).Path
            }
            if (Test-ValidPath -Path $toPath) {
                $toPath = (Resolve-Path $toPath).Path
            }
        }
        else {
            # Fallback to manual validation
            if ($fromPath -and -not [string]::IsNullOrWhiteSpace($fromPath) -and (Test-Path -LiteralPath $fromPath)) {
                $fromPath = (Resolve-Path $fromPath).Path
            }
            if ($toPath -and -not [string]::IsNullOrWhiteSpace($toPath) -and (Test-Path -LiteralPath $toPath)) {
                $toPath = (Resolve-Path $toPath).Path
            }
        }
    }
    catch {
        # Continue with original paths if resolution fails
    }

    # Use .NET Core 2.0+ Path.GetRelativePath if available
    if ([System.IO.Path].GetMethods() | Where-Object { $_.Name -eq 'GetRelativePath' }) {
        try {
            $relative = [System.IO.Path]::GetRelativePath($fromPath, $toPath)
            return $relative
        }
        catch {
            # Fall through to URI-based method
        }
    }

    # Fallback: Use URI-based calculation for older .NET versions
    try {
        $fromUri = [Uri]::new($fromPath)
        $toUri = [Uri]::new($toPath)

        if ($fromUri.Scheme -ne $toUri.Scheme) {
            return $To  # Different schemes, return original
        }

        $relativeUri = $fromUri.MakeRelativeUri($toUri)
        $relativePath = [Uri]::UnescapeDataString($relativeUri.ToString())

        # Convert forward slashes to backslashes on Windows
        if ([Environment]::OSVersion.Platform -eq 'Win32NT') {
            $relativePath = $relativePath -replace '/', '\'
        }

        return $relativePath
    }
    catch {
        # Final fallback: simple string replacement
        if ($toPath.StartsWith($fromPath, [StringComparison]::OrdinalIgnoreCase)) {
            $relative = $toPath.Substring($fromPath.Length).TrimStart([System.IO.Path]::DirectorySeparatorChar, [System.IO.Path]::AltDirectorySeparatorChar)
            if ([string]::IsNullOrEmpty($relative)) {
                return "."
            }
            return $relative
        }
        return $To
    }
}

<#
.SYNOPSIS
    Converts an absolute path to a repository-relative path.

.DESCRIPTION
    Converts an absolute path to a path relative to the repository root. If the path
    is outside the repository or cannot be resolved, returns the original path.

.PARAMETER Path
    The path to convert (can be absolute or relative).

.PARAMETER RepoRoot
    The repository root directory path.

.OUTPUTS
    System.String. The repository-relative path, or the original path if outside repository.

.EXAMPLE
    $relative = ConvertTo-RepoRelativePath -Path "C:\repo\scripts\utils\script.ps1" -RepoRoot "C:\repo"
    # Returns: scripts\utils\script.ps1
#>
function ConvertTo-RepoRelativePath {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [AllowEmptyString()]
        [AllowNull()]
        [string]$Path,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$RepoRoot
    )

    if ([string]::IsNullOrWhiteSpace($Path)) {
        return $Path
    }

    # Try to resolve the path
    # Use Validation module if available
    $useValidation = Get-Command Test-ValidPath -ErrorAction SilentlyContinue
    
    $resolvedPath = $Path
    try {
        if ($useValidation) {
            if (Test-ValidPath -Path $Path) {
                $resolvedPath = (Resolve-Path $Path).ProviderPath
            }
        }
        else {
            # Fallback to manual validation
            if ($Path -and -not [string]::IsNullOrWhiteSpace($Path) -and (Test-Path -LiteralPath $Path)) {
                $resolvedPath = (Resolve-Path $Path).ProviderPath
            }
        }
    }
    catch {
        # Use original path if resolution fails
        $resolvedPath = $Path
    }

    # Normalize paths
    $normalizedRepoRoot = $RepoRoot.TrimEnd([System.IO.Path]::DirectorySeparatorChar, [System.IO.Path]::AltDirectorySeparatorChar)
    $normalizedPath = $resolvedPath.TrimEnd([System.IO.Path]::DirectorySeparatorChar, [System.IO.Path]::AltDirectorySeparatorChar)

    # Check if path is within repository
    if (-not $normalizedPath.StartsWith($normalizedRepoRoot, [StringComparison]::OrdinalIgnoreCase)) {
        return $Path  # Path is outside repository
    }

    # Calculate relative path
    return Get-RelativePath -From $normalizedRepoRoot -To $normalizedPath
}

<#
.SYNOPSIS
    Normalizes a path by resolving it and converting to repository-relative if applicable.

.DESCRIPTION
    Normalizes a path by resolving it to an absolute path, then optionally converting
    it to a repository-relative path. Useful for removing personal absolute paths from
    reports and metrics.

.PARAMETER Path
    The path to normalize.

.PARAMETER RepoRoot
    Optional repository root. If provided, converts to repository-relative path.

.OUTPUTS
    System.String. The normalized path (relative if RepoRoot provided, absolute otherwise).

.EXAMPLE
    $normalized = Normalize-Path -Path "C:\Users\John\repo\scripts\utils\script.ps1" -RepoRoot "C:\Users\John\repo"
    # Returns: scripts\utils\script.ps1
#>
function Normalize-Path {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [AllowEmptyString()]
        [AllowNull()]
        [string]$Path,

        [string]$RepoRoot = $null
    )

    if ([string]::IsNullOrWhiteSpace($Path)) {
        return $Path
    }

    # Use Validation module if available
    $useValidation = Get-Command Test-ValidPath -ErrorAction SilentlyContinue
    
    # If RepoRoot is provided, convert to repository-relative
    $repoRootValid = if ($useValidation) {
        Test-ValidPath -Path $RepoRoot -PathType Directory
    }
    else {
        $RepoRoot -and -not [string]::IsNullOrWhiteSpace($RepoRoot) -and (Test-Path -LiteralPath $RepoRoot)
    }
    
    if ($repoRootValid) {
        return ConvertTo-RepoRelativePath -Path $Path -RepoRoot $RepoRoot
    }

    # Otherwise, just resolve the path
    try {
        $pathValid = if ($useValidation) {
            Test-ValidPath -Path $Path
        }
        else {
            $Path -and -not [string]::IsNullOrWhiteSpace($Path) -and (Test-Path -LiteralPath $Path)
        }
        if ($pathValid) {
            return (Resolve-Path $Path).Path
        }
    }
    catch {
        # Return original if resolution fails
    }

    return $Path
}

Export-ModuleMember -Function @(
    'Get-RelativePath',
    'ConvertTo-RepoRelativePath',
    'Normalize-Path'
)

