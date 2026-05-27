# ===============================================
# File system utility functions
# File Explorer integration
# ===============================================

# Open current directory in the system file manager
<#
.SYNOPSIS
    Opens the current directory in the system file manager.
.DESCRIPTION
    Launches the system file manager in the current directory.
    On Windows uses explorer.exe; on Linux uses xdg-open; on macOS uses open.
#>
function Open-Explorer {
    if ($IsWindows -or $PSVersionTable.Platform -eq 'Win32NT') {
        explorer.exe .
    }
    elseif ($IsMacOS) {
        & open .
    }
    else {
        # Linux: try common file managers via xdg-open, then fallbacks
        if (Test-CachedCommand 'xdg-open') { & xdg-open . }
        elseif (Test-CachedCommand 'nautilus') { & nautilus . }
        elseif (Test-CachedCommand 'dolphin') { & dolphin . }
        elseif (Test-CachedCommand 'thunar') { & thunar . }
        else { Write-Warning 'No file manager found. Install xdg-open or a file manager.' }
    }
}
Set-AgentModeAlias -Name 'open-explorer' -Target 'Open-Explorer'