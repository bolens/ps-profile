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
function wsl-shutdown { wsl --shutdown }

<#
.SYNOPSIS
    Lists all WSL distributions with their status.
.DESCRIPTION
    Displays a verbose list of all installed WSL distributions including their state and version.
#>
function wsl-list { wsl --list --verbose }

<#
.SYNOPSIS
    Launches or switches to Ubuntu WSL distribution.
.DESCRIPTION
    Starts the Ubuntu WSL distribution or switches to it if already running. Passes through any additional arguments.
#>
function ubuntu { wsl -D Ubuntu @args }

























