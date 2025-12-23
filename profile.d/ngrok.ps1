# ===============================================
# ngrok.ps1
# Ngrok tunneling helpers
# ===============================================
# Tier: standard
# Dependencies: bootstrap, env
# Environment: web, development

<#
.SYNOPSIS
    Ngrok tunneling helper functions and aliases.

.DESCRIPTION
    Provides PowerShell functions and aliases for common Ngrok operations.
    Functions check for ngrok availability using Test-HasCommand for efficient
    command detection without triggering module autoload.

.NOTES
    Module: PowerShell.Profile.Ngrok
    Author: PowerShell Profile
#>

# Ngrok execute - run ngrok with arguments
<#
.SYNOPSIS
    Executes Ngrok commands.

.DESCRIPTION
    Wrapper function for Ngrok CLI that checks for command availability before execution.

.PARAMETER Arguments
    Arguments to pass to ngrok.

.EXAMPLE
    Invoke-Ngrok version

.EXAMPLE
    Invoke-Ngrok http 8080
#>
function Invoke-Ngrok {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]]$Arguments
    )
    
    if (Test-CachedCommand ngrok) {
        ngrok @Arguments
    }
    else {
        Write-MissingToolWarning -Tool 'ngrok' -InstallHint 'Install with: scoop install ngrok'
    }
}

# Ngrok HTTP tunnel - expose local HTTP server
<#
.SYNOPSIS
    Creates an Ngrok HTTP tunnel.

.DESCRIPTION
    Wrapper for ngrok http command to expose a local HTTP server.

.PARAMETER Port
    Port number of the local HTTP server (default: 80).

.EXAMPLE
    Start-NgrokHttpTunnel -Port 8080

.EXAMPLE
    Start-NgrokHttpTunnel -Port 3000
#>
function Start-NgrokHttpTunnel {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0)]
        [int]$Port = 80
    )
    
    if (Test-CachedCommand ngrok) {
        ngrok http $Port
    }
    else {
        Write-MissingToolWarning -Tool 'ngrok' -InstallHint 'Install with: scoop install ngrok'
    }
}

# Ngrok TCP tunnel - expose local TCP service
<#
.SYNOPSIS
    Creates an Ngrok TCP tunnel.

.DESCRIPTION
    Wrapper for ngrok tcp command to expose a local TCP service.

.PARAMETER Port
    Port number of the local TCP service.

.EXAMPLE
    Start-NgrokTcpTunnel -Port 22

.EXAMPLE
    Start-NgrokTcpTunnel -Port 3306
#>
function Start-NgrokTcpTunnel {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [int]$Port
    )
    
    if (Test-CachedCommand ngrok) {
        ngrok tcp $Port
    }
    else {
        Write-MissingToolWarning -Tool 'ngrok' -InstallHint 'Install with: scoop install ngrok'
    }
}

# Create aliases for short forms
if (Get-Command -Name 'Set-AgentModeAlias' -ErrorAction SilentlyContinue) {
    Set-AgentModeAlias -Name 'ngrok' -Target 'Invoke-Ngrok'
    Set-AgentModeAlias -Name 'ngrok-http' -Target 'Start-NgrokHttpTunnel'
    Set-AgentModeAlias -Name 'ngrok-tcp' -Target 'Start-NgrokTcpTunnel'
}
else {
    Set-Alias -Name 'ngrok' -Value 'Invoke-Ngrok' -ErrorAction SilentlyContinue
    Set-Alias -Name 'ngrok-http' -Value 'Start-NgrokHttpTunnel' -ErrorAction SilentlyContinue
    Set-Alias -Name 'ngrok-tcp' -Value 'Start-NgrokTcpTunnel' -ErrorAction SilentlyContinue
}
