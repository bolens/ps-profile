# ===============================================
# tailscale.ps1
# Tailscale VPN helpers
# ===============================================
# Tier: standard
# Dependencies: bootstrap, env

<#
.SYNOPSIS
    Tailscale VPN helper functions and aliases.

.DESCRIPTION
    Provides PowerShell functions and aliases for common Tailscale operations.
    Functions check for tailscale availability using Test-HasCommand for efficient
    command detection without triggering module autoload.

.NOTES
    Module: PowerShell.Profile.Tailscale
    Author: PowerShell Profile
#>

# Tailscale execute - run tailscale with arguments
<#
.SYNOPSIS
    Executes Tailscale commands.

.DESCRIPTION
    Wrapper function for Tailscale CLI that checks for command availability before execution.

.PARAMETER Arguments
    Arguments to pass to tailscale.

.EXAMPLE
    Invoke-Tailscale status

.EXAMPLE
    Invoke-Tailscale ping hostname
#>
function Invoke-Tailscale {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]]$Arguments
    )
    
    if (Test-CachedCommand tailscale) {
        tailscale @Arguments
    }
    else {
        Write-MissingToolWarning -Tool 'tailscale' -InstallHint 'Install with: scoop install tailscale'
    }
}

# Tailscale up - connect to Tailscale network
<#
.SYNOPSIS
    Connects to the Tailscale network.

.DESCRIPTION
    Wrapper for tailscale up command.

.PARAMETER Arguments
    Arguments to pass to tailscale up.

.EXAMPLE
    Connect-TailscaleNetwork

.EXAMPLE
    Connect-TailscaleNetwork --accept-routes
#>
function Connect-TailscaleNetwork {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]]$Arguments
    )
    
    if (Test-CachedCommand tailscale) {
        tailscale up @Arguments
    }
    else {
        Write-MissingToolWarning -Tool 'tailscale' -InstallHint 'Install with: scoop install tailscale'
    }
}

# Tailscale down - disconnect from Tailscale network
<#
.SYNOPSIS
    Disconnects from the Tailscale network.

.DESCRIPTION
    Wrapper for tailscale down command.

.EXAMPLE
    Disconnect-TailscaleNetwork
#>
function Disconnect-TailscaleNetwork {
    [CmdletBinding()]
    param()
    
    if (Test-CachedCommand tailscale) {
        tailscale down
    }
    else {
        Write-MissingToolWarning -Tool 'tailscale' -InstallHint 'Install with: scoop install tailscale'
    }
}

# Tailscale status - show connection status
<#
.SYNOPSIS
    Gets Tailscale connection status.

.DESCRIPTION
    Wrapper for tailscale status command.

.EXAMPLE
    Get-TailscaleStatus
#>
function Get-TailscaleStatus {
    [CmdletBinding()]
    param()
    
    if (Test-CachedCommand tailscale) {
        tailscale status
    }
    else {
        Write-MissingToolWarning -Tool 'tailscale' -InstallHint 'Install with: scoop install tailscale'
    }
}

# Create aliases for short forms
if (Get-Command -Name 'Set-AgentModeAlias' -ErrorAction SilentlyContinue) {
    Set-AgentModeAlias -Name 'tailscale' -Target 'Invoke-Tailscale'
    Set-AgentModeAlias -Name 'ts-up' -Target 'Connect-TailscaleNetwork'
    Set-AgentModeAlias -Name 'ts-down' -Target 'Disconnect-TailscaleNetwork'
    Set-AgentModeAlias -Name 'ts-status' -Target 'Get-TailscaleStatus'
}
else {
    Set-Alias -Name 'tailscale' -Value 'Invoke-Tailscale' -ErrorAction SilentlyContinue
    Set-Alias -Name 'ts-up' -Value 'Connect-TailscaleNetwork' -ErrorAction SilentlyContinue
    Set-Alias -Name 'ts-down' -Value 'Disconnect-TailscaleNetwork' -ErrorAction SilentlyContinue
    Set-Alias -Name 'ts-status' -Value 'Get-TailscaleStatus' -ErrorAction SilentlyContinue
}
