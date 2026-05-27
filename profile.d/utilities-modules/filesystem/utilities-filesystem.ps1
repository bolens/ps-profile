# ===============================================
# File system utility functions
# File Explorer integration
# ===============================================

# Open current directory in File Explorer
<#
.SYNOPSIS
    Opens current directory in File Explorer.
.DESCRIPTION
    Launches Windows File Explorer in the current directory.
#>
function Open-Explorer { explorer.exe . }
Set-AgentModeAlias -Name 'open-explorer' -Target 'Open-Explorer'