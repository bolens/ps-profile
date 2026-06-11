<#
scripts/lib/PowerShellDetection.psm1

.SYNOPSIS
    PowerShell executable detection utilities.

.DESCRIPTION
    Provides functions for detecting the appropriate PowerShell executable for the current environment.
#>

<#
.SYNOPSIS
    Gets the appropriate PowerShell executable name for the current environment.

.DESCRIPTION
    Returns 'pwsh' for PowerShell Core or 'powershell' for Windows PowerShell.
    Useful for scripts that need to spawn PowerShell processes.

.OUTPUTS
    System.String. The PowerShell executable name ('pwsh' or 'powershell').

.EXAMPLE
    $psExe = Get-PowerShellExecutable
    & $psExe -NoProfile -File $scriptPath
#>
function Get-PowerShellExecutable {
    [CmdletBinding()]
    [OutputType([string])]
    param()

    $forcedEdition = [Environment]::GetEnvironmentVariable('PS_PROFILE_POWERSHELL_DETECTION_FORCE_EDITION')
    if (-not [string]::IsNullOrWhiteSpace($forcedEdition)) {
        $normalized = $forcedEdition.Trim().ToLowerInvariant()
        if ($normalized -in @('desktop', 'windows', 'win', 'powershell', 'windows powershell')) {
            return 'powershell'
        }
        if ($normalized -in @('core', 'pwsh', 'powershell core')) {
            return 'pwsh'
        }
    }

    if ($PSVersionTable.PSEdition -eq 'Core') {
        return 'pwsh'
    }

    return 'powershell'
}

Export-ModuleMember -Function Get-PowerShellExecutable

