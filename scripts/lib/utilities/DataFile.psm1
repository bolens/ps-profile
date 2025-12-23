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

# Import SafeImport module if available for safer imports
# Note: We need to use manual check here since SafeImport itself uses Validation
$safeImportModulePath = Join-Path (Split-Path -Parent $PSScriptRoot) 'core' 'SafeImport.psm1'
if ($safeImportModulePath -and -not [string]::IsNullOrWhiteSpace($safeImportModulePath) -and (Test-Path -LiteralPath $safeImportModulePath)) {
    Import-Module $safeImportModulePath -DisableNameChecking -ErrorAction SilentlyContinue
}

# Import Cache module for caching support
$cacheModulePath = Join-Path $PSScriptRoot 'Cache.psm1'
if (Get-Command Import-ModuleSafely -ErrorAction SilentlyContinue) {
    Import-ModuleSafely -ModulePath $cacheModulePath -ErrorAction SilentlyContinue
}
else {
    # Fallback to manual validation
    if ($cacheModulePath -and -not [string]::IsNullOrWhiteSpace($cacheModulePath) -and (Test-Path -LiteralPath $cacheModulePath)) {
        Import-Module $cacheModulePath -ErrorAction SilentlyContinue
    }
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
    $config = Import-CachedPowerShellDataFile -Path 'config.psd1'
    
    # NOTE: For requirements files, use Import-Requirements from RequirementsLoader.psm1:
    # Import-Module RequirementsLoader
    # $requirements = Import-Requirements -RepoRoot $repoRoot
#>
function Import-CachedPowerShellDataFile {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory)]
        [string]$Path,

        [int]$ExpirationSeconds = 300
    )

    # Initialize result variable to ensure we always return something
    $result = $null

    # Use Validation module if available
    if (Get-Command Test-ValidPath -ErrorAction SilentlyContinue) {
        if (-not (Test-ValidPath -Path $Path -PathType File)) {
            throw "File not found: $Path"
        }
    }
    else {
        # Fallback to manual validation
        if (-not (Test-Path -Path $Path)) {
            throw "File not found: $Path"
        }
    }

    # Use file path and modification time as cache key
    # Use CacheKey module if available for consistent key generation
    $cacheKey = if (Get-Command New-FileCacheKey -ErrorAction SilentlyContinue) {
        New-FileCacheKey -FilePath $Path -Prefix 'PowerShellDataFile'
    }
    else {
        # Fallback to manual cache key generation
        $fileInfo = Get-Item -Path $Path
        "PowerShellDataFile_$($fileInfo.FullName)_$($fileInfo.LastWriteTimeUtc.Ticks)"
    }
    
    # Check cache
    if (Get-Command Get-CachedValue -ErrorAction SilentlyContinue) {
        $cachedResult = Get-CachedValue -Key $cacheKey
        # Check if cached result exists (including empty hashtables)
        # Note: Empty hashtable @{} is not null, so we need to check if it's actually a hashtable
        if ($null -ne $cachedResult) {
            Write-Verbose "Using cached data for $Path"
            # Ensure cached result is a hashtable
            if ($cachedResult -is [hashtable]) {
                return $cachedResult
            }
            # If cache returned something unexpected (not a hashtable), fall through to re-import
            Write-Verbose "Cached value is not a hashtable (type: $($cachedResult.GetType().FullName)), re-importing"
        }
    }

    # Import and cache
    try {
        $result = Import-PowerShellDataFile -Path $Path -ErrorAction Stop
        Write-Verbose "Import-PowerShellDataFile returned: $($null -eq $result), Type: $(if ($result) { $result.GetType().FullName } else { 'null' })"
        # Ensure we return a hashtable even if Import-PowerShellDataFile returns null for empty hashtables
        # This can happen with empty hashtables or whitespace-only files
        if ($null -eq $result) {
            Write-Verbose "Import-PowerShellDataFile returned null, creating empty hashtable"
            $result = @{}
        }
        # Also ensure result is a hashtable (not PSCustomObject or other type)
        if ($result -isnot [hashtable]) {
            Write-Verbose "Import-PowerShellDataFile returned non-hashtable, creating empty hashtable"
            $result = @{}
        }
        Write-Verbose "Final result: $($null -eq $result), Type: $(if ($result) { $result.GetType().FullName } else { 'null' }), Count: $(if ($result) { $result.Count } else { 'N/A' })"
        # Double-check: ensure we always return a hashtable (defensive programming)
        if ($null -eq $result -or $result -isnot [hashtable]) {
            Write-Verbose "Result is null or not a hashtable, forcing empty hashtable"
            $result = @{}
        }
        if (Get-Command Set-CachedValue -ErrorAction SilentlyContinue) {
            Set-CachedValue -Key $cacheKey -Value $result -ExpirationSeconds $ExpirationSeconds
        }
    }
    catch {
        # Import-PowerShellDataFile can throw for various reasons
        # For empty hashtables or whitespace files, return empty hashtable instead of throwing
        # Check if file content is essentially empty (just whitespace or empty hashtable)
        $shouldReturnEmpty = $false
        try {
            $fileContent = Get-Content -Path $Path -Raw -ErrorAction Stop
            $trimmedContent = if ($fileContent) { $fileContent.Trim() } else { '' }
            # If file contains only '@{}' or whitespace, return empty hashtable
            if ($trimmedContent -eq '@{}' -or $trimmedContent -eq '' -or [string]::IsNullOrWhiteSpace($trimmedContent)) {
                $shouldReturnEmpty = $true
            }
        }
        catch {
            # If we can't read the file, check if exception suggests empty content
            if ($_.Exception.Message -match 'empty|whitespace|no data|at line') {
                $shouldReturnEmpty = $true
            }
        }
        
        if ($shouldReturnEmpty) {
            $result = @{}
            if (Get-Command Set-CachedValue -ErrorAction SilentlyContinue) {
                Set-CachedValue -Key $cacheKey -Value $result -ExpirationSeconds $ExpirationSeconds
            }
        }
        else {
            throw "Failed to import PowerShell data file $Path`: $($_.Exception.Message)"
        }
    }
    
    # Final safety check - ensure we always return a hashtable
    if ($null -eq $result -or $result -isnot [hashtable]) {
        Write-Verbose "Final safety check: forcing empty hashtable return"
        $result = @{}
    }
    
    return $result
}

# Export functions
Export-ModuleMember -Function 'Import-CachedPowerShellDataFile'

