<#
scripts/lib/Command.psm1

.SYNOPSIS
    Command availability checking utilities.

.DESCRIPTION
    Provides functions for checking if commands are available on the system,
    with caching support for performance.

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
    Tests if a command is available on the system.

.DESCRIPTION
    Checks if a command (executable, function, cmdlet, or alias) is available.
    Uses Test-HasCommand if available from profile, otherwise falls back to Get-Command.
    This provides a consistent way to check command availability across scripts.

.PARAMETER CommandName
    The name of the command to check.

.OUTPUTS
    System.Boolean. Returns $true if command is available, $false otherwise.

.EXAMPLE
    if (Test-CommandAvailable -CommandName 'git') {
        & git --version
    }
#>
function Test-CommandAvailable {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory)]
        [string]$CommandName
    )

    # Check cache first (cache for 5 minutes)
    $cacheKey = "CommandAvailable_$CommandName"
    if (Get-Command Get-CachedValue -ErrorAction SilentlyContinue) {
        $cachedResult = Get-CachedValue -Key $cacheKey
        if ($null -ne $cachedResult) {
            return $cachedResult
        }
    }

    # Use Test-HasCommand if available from profile (more efficient)
    if ((Test-Path Function:Test-HasCommand) -or (Get-Command Test-HasCommand -ErrorAction SilentlyContinue)) {
        $result = Test-HasCommand $CommandName
        if (Get-Command Set-CachedValue -ErrorAction SilentlyContinue) {
            Set-CachedValue -Key $cacheKey -Value $result -ExpirationSeconds 300
        }
        return $result
    }

    # Fallback: use Get-Command
    $command = Get-Command -Name $CommandName -ErrorAction SilentlyContinue
    $result = $null -ne $command
    if (Get-Command Set-CachedValue -ErrorAction SilentlyContinue) {
        Set-CachedValue -Key $cacheKey -Value $result -ExpirationSeconds 300
    }
    return $result
}

# Export functions
Export-ModuleMember -Function 'Test-CommandAvailable'

