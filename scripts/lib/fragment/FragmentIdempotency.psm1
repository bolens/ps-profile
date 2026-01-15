<#
scripts/lib/FragmentIdempotency.psm1

.SYNOPSIS
    Fragment idempotency management utilities.

.DESCRIPTION
    Provides functions for checking and managing fragment loading state to ensure
    idempotency. Fragments can be safely loaded multiple times without side effects.

.NOTES
    Module Version: 1.0.0
    PowerShell Version: 3.0+
#>

<#
.SYNOPSIS
    Tests if a fragment has been loaded.

.DESCRIPTION
    Checks if a fragment has been marked as loaded by checking for a global
    variable named '{FragmentName}Loaded'.

.PARAMETER FragmentName
    The name of the fragment to check (without .ps1 extension).

.OUTPUTS
    System.Boolean. $true if the fragment is loaded, $false otherwise.

.EXAMPLE
    if (Test-FragmentLoaded -FragmentName '11-git') {
        Write-Host "Git fragment already loaded"
    }
#>
function Test-FragmentLoaded {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory = $false)]
        [AllowEmptyString()]
        [string]$FragmentName
    )

    if ([string]::IsNullOrWhiteSpace($FragmentName)) {
        return $false
    }

    $variableName = "${FragmentName}Loaded"
    $loaded = Get-Variable -Name $variableName -Scope Global -ErrorAction SilentlyContinue
    $isLoaded = ($null -ne $loaded)
    
    $debugLevel = 0
    $hasDebug = $false
    if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel)) {
        $hasDebug = $debugLevel -ge 1
    }
    
    # Level 3: Log detailed idempotency check
    if ($hasDebug -and $debugLevel -ge 3) {
        Write-Host "  [fragment-idempotency.test] Fragment '$FragmentName' loaded state: $isLoaded (variable: $variableName)" -ForegroundColor DarkGray
    }
    
    return $isLoaded
}

<#
.SYNOPSIS
    Marks a fragment as loaded.

.DESCRIPTION
    Sets a global variable to mark a fragment as loaded, enabling idempotency checks.

.PARAMETER FragmentName
    The name of the fragment to mark (without .ps1 extension).

.EXAMPLE
    Set-FragmentLoaded -FragmentName '11-git'
#>
function Set-FragmentLoaded {
    [CmdletBinding()]
    [OutputType([void])]
    param(
        [Parameter(Mandatory)]
        [string]$FragmentName
    )

    if ([string]::IsNullOrWhiteSpace($FragmentName)) {
        return
    }

    $variableName = "${FragmentName}Loaded"
    Set-Variable -Name $variableName -Value $true -Scope Global -Force | Out-Null
    
    $debugLevel = 0
    $hasDebug = $false
    if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel)) {
        $hasDebug = $debugLevel -ge 1
    }
    
    # Level 3: Log detailed idempotency marking
    if ($hasDebug -and $debugLevel -ge 3) {
        Write-Host "  [fragment-idempotency.set] Marked fragment '$FragmentName' as loaded (variable: $variableName)" -ForegroundColor DarkGray
    }
}

<#
.SYNOPSIS
    Clears the loaded state for a fragment.

.DESCRIPTION
    Removes the global variable that marks a fragment as loaded, allowing it to be
    loaded again. Useful for testing or reloading fragments.

.PARAMETER FragmentName
    The name of the fragment to clear (without .ps1 extension).

.EXAMPLE
    Clear-FragmentLoaded -FragmentName '11-git'
#>
function Clear-FragmentLoaded {
    [CmdletBinding()]
    [OutputType([void])]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$FragmentName
    )

    if ([string]::IsNullOrWhiteSpace($FragmentName)) {
        return
    }

    $variableName = "${FragmentName}Loaded"
    $existed = (Get-Variable -Name $variableName -Scope Global -ErrorAction SilentlyContinue) -ne $null
    Remove-Variable -Name $variableName -Scope Global -ErrorAction SilentlyContinue
    
    $debugLevel = 0
    $hasDebug = $false
    if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel)) {
        $hasDebug = $debugLevel -ge 1
    }
    
    # Level 3: Log detailed idempotency clearing
    if ($hasDebug -and $debugLevel -ge 3) {
        if ($existed) {
            Write-Host "  [fragment-idempotency.clear] Cleared loaded state for fragment '$FragmentName' (variable: $variableName)" -ForegroundColor DarkGray
        }
        else {
            Write-Host "  [fragment-idempotency.clear] Fragment '$FragmentName' was not marked as loaded (variable: $variableName)" -ForegroundColor DarkGray
        }
    }
}

<#
.SYNOPSIS
    Gets the standard idempotency check script block.

.DESCRIPTION
    Returns a script block that performs the standard idempotency check pattern
    used across fragments. This can be used to ensure consistent behavior.

.PARAMETER FragmentName
    The name of the fragment to check (without .ps1 extension).

.OUTPUTS
    System.Management.Automation.ScriptBlock. Script block that returns $true
    if fragment should be skipped (already loaded), $false otherwise.

.EXAMPLE
    $shouldSkip = & (Get-FragmentIdempotencyCheck -FragmentName '11-git')
    if ($shouldSkip) { return }
#>
function Get-FragmentIdempotencyCheck {
    [CmdletBinding()]
    [OutputType([scriptblock])]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$FragmentName
    )

    $variableName = "${FragmentName}Loaded"
    return {
        $null -ne (Get-Variable -Name $variableName -Scope Global -ErrorAction SilentlyContinue)
    }.GetNewClosure()
}

Export-ModuleMember -Function @(
    'Test-FragmentLoaded',
    'Set-FragmentLoaded',
    'Clear-FragmentLoaded',
    'Get-FragmentIdempotencyCheck'
)


