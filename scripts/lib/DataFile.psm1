<#
scripts/lib/DataFile.psm1

.SYNOPSIS
    PowerShell data file import utilities with caching.

.DESCRIPTION
    Provides functions for importing PowerShell data files (.psd1) with caching
    support to avoid re-parsing the same file multiple times.

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
    Imports a PowerShell data file with caching support.

.DESCRIPTION
    Imports a PowerShell data file (.psd1) with caching to avoid re-parsing
    the same file multiple times. Useful for requirements files, settings files, etc.
    Cache expires after 5 minutes or when file modification time changes.

.PARAMETER Path
    Path to the PowerShell data file to import.

.PARAMETER ExpirationSeconds
    Number of seconds before cache expires. Defaults to 300 (5 minutes).

.OUTPUTS
    Hashtable or PSCustomObject containing the imported data.

.EXAMPLE
    $requirements = Import-CachedPowerShellDataFile -Path 'requirements.psd1'
#>
function Import-CachedPowerShellDataFile {
    [CmdletBinding()]
    [OutputType([object])]
    param(
        [Parameter(Mandatory)]
        [string]$Path,

        [int]$ExpirationSeconds = 300
    )

    if (-not (Test-Path -Path $Path)) {
        throw "File not found: $Path"
    }

    # Use file path and modification time as cache key
    $fileInfo = Get-Item -Path $Path
    $cacheKey = "PowerShellDataFile_$($fileInfo.FullName)_$($fileInfo.LastWriteTimeUtc.Ticks)"
    
    # Check cache
    if (Get-Command Get-CachedValue -ErrorAction SilentlyContinue) {
        $cachedResult = Get-CachedValue -Key $cacheKey
        if ($null -ne $cachedResult) {
            Write-Verbose "Using cached data for $Path"
            return $cachedResult
        }
    }

    # Import and cache
    try {
        $result = Import-PowerShellDataFile -Path $Path -ErrorAction Stop
        if (Get-Command Set-CachedValue -ErrorAction SilentlyContinue) {
            Set-CachedValue -Key $cacheKey -Value $result -ExpirationSeconds $ExpirationSeconds
        }
        return $result
    }
    catch {
        throw "Failed to import PowerShell data file $Path`: $($_.Exception.Message)"
    }
}

# Export functions
Export-ModuleMember -Function 'Import-CachedPowerShellDataFile'

