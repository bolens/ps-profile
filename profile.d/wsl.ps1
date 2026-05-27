# ===============================================
# wsl.ps1
# WSL helpers and shorthands
# ===============================================
# Tier: essential
# Dependencies: bootstrap, env

<#
.SYNOPSIS
    Shuts down all WSL distributions.
.DESCRIPTION
    Terminates all running WSL distributions and shuts down the WSL subsystem.
#>
function Stop-WSL { wsl --shutdown }
Set-AgentModeAlias -Name 'wsl-shutdown' -Target 'Stop-WSL'
<#
.SYNOPSIS
    Lists all WSL distributions with their status.
.DESCRIPTION
    Displays a verbose list of all installed WSL distributions including their state and version.
#>
function Get-WSLDistribution { wsl --list --verbose }
Set-AgentModeAlias -Name 'wsl-list' -Target 'Get-WSLDistribution'
<#
.SYNOPSIS
    Launches or switches to Ubuntu WSL distribution.
.DESCRIPTION
    Starts the Ubuntu WSL distribution or switches to it if already running. Passes through any additional arguments.
#>
function Start-UbuntuWSL { wsl -D Ubuntu @args }
Set-AgentModeAlias -Name 'ubuntu' -Target 'Start-UbuntuWSL'