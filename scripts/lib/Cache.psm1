<#
scripts/lib/Cache.psm1

.SYNOPSIS
    Caching utilities for expensive operations.

.DESCRIPTION
    Provides simple caching functionality for expensive operations. Values are cached
    in memory with an optional expiration time. Useful for caching command availability
    checks, module version lookups, and other expensive operations.

.NOTES
    Module Version: 1.0.0
    PowerShell Version: 3.0+
#>

<#
.SYNOPSIS
    Gets or sets a cached value with expiration.

.DESCRIPTION
    Provides simple caching functionality for expensive operations. Values are cached
    in memory with an optional expiration time. Useful for caching command availability
    checks, module version lookups, and other expensive operations.

.PARAMETER Key
    The cache key to retrieve or set.

.PARAMETER Value
    The value to cache. If not provided, retrieves the cached value.

.PARAMETER ExpirationSeconds
    Number of seconds before the cache entry expires. Defaults to 300 (5 minutes).

.PARAMETER Clear
    If specified, clears the cache entry for the given key.

.OUTPUTS
    The cached value if retrieving, or $null if setting.

.EXAMPLE
    # Cache a value
    Set-CachedValue -Key 'ModuleVersion' -Value '1.2.3' -ExpirationSeconds 600

    # Retrieve cached value
    $version = Get-CachedValue -Key 'ModuleVersion'

    # Clear cache
    Clear-CachedValue -Key 'ModuleVersion'
#>
function Get-CachedValue {
    [CmdletBinding()]
    [OutputType([object])]
    param(
        [Parameter(Mandatory)]
        [string]$Key,

        [object]$Value,

        [int]$ExpirationSeconds = 300,

        [switch]$Clear
    )

    # Initialize cache if it doesn't exist
    if (-not $script:ValueCache) {
        $script:ValueCache = @{}
        $script:ValueCacheExpiry = @{}
    }

    # Clear cache entry if requested
    if ($Clear) {
        $script:ValueCache.Remove($Key) | Out-Null
        $script:ValueCacheExpiry.Remove($Key) | Out-Null
        return $null
    }

    # Check if value exists and hasn't expired
    if ($script:ValueCache.ContainsKey($Key)) {
        $expiryTime = $script:ValueCacheExpiry[$Key]
        if ($expiryTime -gt [DateTime]::Now) {
            # Return cached value
            return $script:ValueCache[$Key]
        }
        else {
            # Expired, remove it
            $script:ValueCache.Remove($Key) | Out-Null
            $script:ValueCacheExpiry.Remove($Key) | Out-Null
        }
    }

    # If Value parameter provided, cache it
    if ($PSBoundParameters.ContainsKey('Value')) {
        $script:ValueCache[$Key] = $Value
        $script:ValueCacheExpiry[$Key] = [DateTime]::Now.AddSeconds($ExpirationSeconds)
        return $null
    }

    # No cached value found
    return $null
}

function Set-CachedValue {
    [CmdletBinding()]
    [OutputType([void])]
    param(
        [Parameter(Mandatory)]
        [string]$Key,

        [Parameter(Mandatory)]
        [object]$Value,

        [int]$ExpirationSeconds = 300
    )

    Get-CachedValue -Key $Key -Value $Value -ExpirationSeconds $ExpirationSeconds | Out-Null
}

function Clear-CachedValue {
    [CmdletBinding()]
    [OutputType([void])]
    param(
        [Parameter(Mandatory)]
        [string]$Key
    )

    Get-CachedValue -Key $Key -Clear | Out-Null
}

# Export functions
Export-ModuleMember -Function @(
    'Get-CachedValue',
    'Set-CachedValue',
    'Clear-CachedValue'
)

