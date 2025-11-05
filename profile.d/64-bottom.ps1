# ===============================================
# 64-bottom.ps1
# System monitor with bottom
# ===============================================

# Bottom aliases
# Requires: bottom (https://github.com/ClementTsang/bottom)

if (Get-Command btm -ErrorAction SilentlyContinue) {
    # Main bottom command
    <#
    .SYNOPSIS
        Launches bottom system monitor.
    .DESCRIPTION
        Opens bottom (btm), a cross-platform graphical process/system monitor. Provides an interactive, real-time view of system resources including CPU, memory, disk, and network usage.
    #>
    Set-Alias -Name top -Value btm -Option AllScope -Force
    
    <#
    .SYNOPSIS
        Launches bottom system monitor.
    .DESCRIPTION
        Opens bottom (btm), a cross-platform graphical process/system monitor. Provides an interactive, real-time view of system resources including CPU, memory, disk, and network usage.
    #>
    Set-Alias -Name htop -Value btm -Option AllScope -Force
    
    <#
    .SYNOPSIS
        Launches bottom system monitor.
    .DESCRIPTION
        Opens bottom (btm), a cross-platform graphical process/system monitor. Provides an interactive, real-time view of system resources including CPU, memory, disk, and network usage.
    #>
    Set-Alias -Name monitor -Value btm -Option AllScope -Force
}
elseif (Get-Command bottom -ErrorAction SilentlyContinue) {
    <#
    .SYNOPSIS
        Launches bottom system monitor.
    .DESCRIPTION
        Opens bottom, a cross-platform graphical process/system monitor. Provides an interactive, real-time view of system resources including CPU, memory, disk, and network usage.
    #>
    Set-Alias -Name top -Value bottom -Option AllScope -Force
    
    <#
    .SYNOPSIS
        Launches bottom system monitor.
    .DESCRIPTION
        Opens bottom, a cross-platform graphical process/system monitor. Provides an interactive, real-time view of system resources including CPU, memory, disk, and network usage.
    #>
    Set-Alias -Name htop -Value bottom -Option AllScope -Force
    
    <#
    .SYNOPSIS
        Launches bottom system monitor.
    .DESCRIPTION
        Opens bottom, a cross-platform graphical process/system monitor. Provides an interactive, real-time view of system resources including CPU, memory, disk, and network usage.
    #>
    Set-Alias -Name monitor -Value bottom -Option AllScope -Force
}
else {
    Write-Warning "bottom (btm) not found. Install with: scoop install bottom"
}
