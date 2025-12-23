# ===============================================
# ModulePathCache.ps1
# Module path existence caching utilities
# ===============================================

# Initialize module path cache if not already present
if (-not (Get-Variable -Name 'PSProfileModulePathCache' -Scope Global -ErrorAction SilentlyContinue)) {
    $global:PSProfileModulePathCache = [System.Collections.Concurrent.ConcurrentDictionary[string, bool]]::new([System.StringComparer]::OrdinalIgnoreCase)
}

<#
.SYNOPSIS
    Tests if a module path exists, using a cache to avoid redundant filesystem operations.

.DESCRIPTION
    Checks if a module file path exists, caching the result to avoid repeated Test-Path calls
    during profile loading. This significantly improves performance when many modules are
    loaded, especially in fragments like files.ps1 that load 100+ modules.

.PARAMETER Path
    The path to the module file to check.

.OUTPUTS
    System.Boolean. True if the path exists, false otherwise.

.EXAMPLE
    if (Test-ModulePath -Path $modulePath) {
        Import-Module $modulePath
    }

    Checks if a module path exists before importing it.
#>
function global:Test-ModulePath {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$Path
    )

    if ([string]::IsNullOrWhiteSpace($Path)) {
        return $false
    }

    # Normalize path for consistent caching (resolve relative paths, handle case-insensitive)
    try {
        $normalizedPath = [System.IO.Path]::GetFullPath($Path)
    }
    catch {
        # If path resolution fails, use original path
        $normalizedPath = $Path
    }

    # Check cache first
    if ($global:PSProfileModulePathCache.ContainsKey($normalizedPath)) {
        return $global:PSProfileModulePathCache[$normalizedPath]
    }

    # Cache miss: perform actual Test-Path and cache result
    if ($normalizedPath -and -not [string]::IsNullOrWhiteSpace($normalizedPath)) {
        $exists = Test-Path -LiteralPath $normalizedPath -ErrorAction SilentlyContinue
        $global:PSProfileModulePathCache[$normalizedPath] = $exists
        return $exists
    }
    else {
        # Path is null or empty after normalization
        $global:PSProfileModulePathCache[$normalizedPath] = $false
        return $false
    }
}

<#
.SYNOPSIS
    Clears the module path existence cache.

.DESCRIPTION
    Empties the in-memory cache so that subsequent Test-ModulePath invocations
    re-check paths. Useful for testing or when module files are added/removed.

.OUTPUTS
    System.Boolean. True if cache was cleared, false if cache didn't exist.
#>
function global:Clear-ModulePathCache {
    [CmdletBinding()]
    [OutputType([bool])]
    param()

    if (-not $global:PSProfileModulePathCache) {
        return $false
    }

    $global:PSProfileModulePathCache.Clear()
    return $true
}

<#
.SYNOPSIS
    Removes a single entry from the module path cache.

.DESCRIPTION
    Deletes the cached existence result for the specified path, forcing the next
    lookup to check the filesystem again. Useful when a module file is added or removed.

.PARAMETER Path
    The path whose cached result should be removed.

.OUTPUTS
    System.Boolean. True if entry was removed, false otherwise.
#>
function global:Remove-ModulePathCacheEntry {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    if (-not $global:PSProfileModulePathCache -or [string]::IsNullOrWhiteSpace($Path)) {
        return $false
    }

    try {
        $normalizedPath = [System.IO.Path]::GetFullPath($Path)
    }
    catch {
        $normalizedPath = $Path
    }

    $removedEntry = $null
    return $global:PSProfileModulePathCache.TryRemove($normalizedPath, [ref]$removedEntry)
}

