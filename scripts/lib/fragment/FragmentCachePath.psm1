<#
.SYNOPSIS
    Cross-platform fragment cache path resolution.

.DESCRIPTION
    Cross-platform fragment cache path resolution.

.PARAMETER EnsureExists
    EnsureExists parameter.

    .PARAMETER EnsureExists
    EnsureExists parameter.

.EXAMPLE

    .EXAMPLE
    Get-FragmentCacheDirectory
#>

$platformPathsModule = Join-Path (Split-Path $PSScriptRoot -Parent) 'core' 'PlatformPaths.psm1'
if (Test-Path -LiteralPath $platformPathsModule) {
    Import-Module $platformPathsModule -DisableNameChecking -ErrorAction Stop
}

function Get-FragmentCacheDirectory {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [switch]$EnsureExists
    )

    $cacheDir = Get-CacheDirectory

    if ($env:PS_PROFILE_CACHE_DIR -and $cacheDir -eq $env:PS_PROFILE_CACHE_DIR -and -not [System.IO.Path]::IsPathRooted($cacheDir)) {
        $cacheDir = Join-Path (Get-Location).Path $cacheDir
    }

    if ($EnsureExists -and $cacheDir -and -not (Test-Path -LiteralPath $cacheDir)) {
        New-Item -ItemType Directory -Path $cacheDir -Force | Out-Null
    }

    return $cacheDir
}

<#
.SYNOPSIS
    Gets the path to the fragment cache SQLite database.

.DESCRIPTION
    Gets the path to the fragment cache SQLite database.

.PARAMETER EnsureExists
    Creates the cache directory when it does not exist.

    .PARAMETER EnsureExists
    Creates the cache directory when it does not exist.

.OUTPUTS
    System.String

    .OUTPUTS
    System.String

.EXAMPLE

    .EXAMPLE
    Get-FragmentCacheDbPath
#>
function Get-FragmentCacheDbPath {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [switch]$EnsureExists
    )

    $cacheDir = Get-FragmentCacheDirectory -EnsureExists:$EnsureExists
    if (-not $cacheDir) {
        throw 'Unable to determine fragment cache directory.'
    }

    return Join-Path $cacheDir 'fragment-cache.db'
}

Export-ModuleMember -Function @(
    'Get-FragmentCacheDirectory'
    'Get-FragmentCacheDbPath'
)
