# ===============================================
# Profile management utility functions
# Profile reloading, editing, backup, and function listing
# ===============================================

# Reload profile in current session
<#
.SYNOPSIS
    Reloads the PowerShell profile.
.DESCRIPTION
    Dots-sources the current profile file to reload all functions and settings.
#>
function Reload-Profile { .$PROFILE }
Set-Alias -Name reload -Value Reload-Profile -ErrorAction SilentlyContinue

# Edit profile in code editor
<#
.SYNOPSIS
    Opens the profile in VS Code.
.DESCRIPTION
    Launches VS Code to edit the current PowerShell profile file.
#>
function Edit-Profile { code $PROFILE }
Set-Alias -Name edit-profile -Value Edit-Profile -ErrorAction SilentlyContinue

# Backup current profile to timestamped .bak file
<#
.SYNOPSIS
    Creates a backup of the profile.
.DESCRIPTION
    Creates a timestamped backup copy of the current PowerShell profile.
#>
function Backup-Profile { Copy-Item $PROFILE ($PROFILE + '.' + (Get-Date -Format 'yyyyMMddHHmmss') + '.bak') }
Set-Alias -Name backup-profile -Value Backup-Profile -ErrorAction SilentlyContinue

# List all user-defined functions in current session
<#
.SYNOPSIS
    Lists user-defined functions.
.DESCRIPTION
    Displays all user-defined functions in the current PowerShell session.
#>
function Get-Functions { @(Get-Command -CommandType Function | Where-Object { $_.Source -eq '' } | Select-Object Name, Definition) }
Set-Alias -Name list-functions -Value Get-Functions -ErrorAction SilentlyContinue

