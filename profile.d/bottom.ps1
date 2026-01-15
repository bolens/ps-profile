# ===============================================
# bottom.ps1
# System monitor with bottom
# ===============================================

# Bottom aliases
# Requires: bottom (https://github.com/ClementTsang/bottom)
# Tier: standard
# Dependencies: bootstrap, env

$bottomCmd = $null
# Defensive check: ensure Test-CachedCommand is available (bootstrap must load first)
if ((Get-Command Test-CachedCommand -ErrorAction SilentlyContinue) -and (Test-CachedCommand btm)) {
    $bottomCmd = 'btm'
}
elseif ((Get-Command Test-CachedCommand -ErrorAction SilentlyContinue) -and (Test-CachedCommand bottom)) {
    $bottomCmd = 'bottom'
}

if ($bottomCmd) {
    <#
    .SYNOPSIS
        Launches bottom system monitor.
    .DESCRIPTION
        Opens bottom, a cross-platform graphical process/system monitor. Provides an interactive, real-time view of system resources including CPU, memory, disk, and network usage.
    #>
    Set-Alias -Name top -Value $bottomCmd -Option AllScope -Force

    <#
    .SYNOPSIS
        Launches bottom system monitor.
    .DESCRIPTION
        Opens bottom, a cross-platform graphical process/system monitor. Provides an interactive, real-time view of system resources including CPU, memory, disk, and network usage.
    #>
    Set-Alias -Name htop -Value $bottomCmd -Option AllScope -Force

    <#
    .SYNOPSIS
        Launches bottom system monitor.
    .DESCRIPTION
        Opens bottom, a cross-platform graphical process/system monitor. Provides an interactive, real-time view of system resources including CPU, memory, disk, and network usage.
    #>
    Set-Alias -Name monitor -Value $bottomCmd -Option AllScope -Force
}
else {
    Write-MissingToolWarning -Tool 'bottom' -Message 'bottom (btm) not found. Install with: scoop install bottom'
}
