# ===============================================
# Command history utility functions
# History viewing and searching
# ===============================================

# History helpers
<#
.SYNOPSIS
    Shows recent command history.
.DESCRIPTION
    Displays the last 20 commands from the PowerShell command history.
#>
function Get-History { Microsoft.PowerShell.Core\Get-History | Select-Object -Last 20 }

# Search history
<#
.SYNOPSIS
    Searches command history.
.DESCRIPTION
    Searches through PowerShell command history for the specified pattern.
#>
function Find-History { Microsoft.PowerShell.Core\Get-History | Select-String $args }
Set-Alias -Name hg -Value Find-History -ErrorAction SilentlyContinue

