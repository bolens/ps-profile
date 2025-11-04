# ===============================================
# 10-wsl.ps1
# WSL helpers and shorthands
# ===============================================

<#
.SYNOPSIS
    Shuts down all WSL distributions.
.DESCRIPTION
    Terminates all running WSL distributions and shuts down the WSL subsystem.
#>
function Stop-WSL { wsl --shutdown }
Set-Alias -Name wsl-shutdown -Value Stop-WSL -ErrorAction SilentlyContinue

<#
.SYNOPSIS
    Lists all WSL distributions with their status.
.DESCRIPTION
    Displays a verbose list of all installed WSL distributions including their state and version.
#>
function Get-WSLDistribution { wsl --list --verbose }
Set-Alias -Name wsl-list -Value Get-WSLDistribution -ErrorAction SilentlyContinue

<#
.SYNOPSIS
    Launches or switches to Ubuntu WSL distribution.
.DESCRIPTION
    Starts the Ubuntu WSL distribution or switches to it if already running. Passes through any additional arguments.
#>
function Start-UbuntuWSL { wsl -D Ubuntu @args }
Set-Alias -Name ubuntu -Value Start-UbuntuWSL -ErrorAction SilentlyContinue
