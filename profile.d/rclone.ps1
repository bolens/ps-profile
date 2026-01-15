# ===============================================
# rclone.ps1
# rclone convenience helpers
# ===============================================
# Tier: essential
# Dependencies: bootstrap, env

<#
.SYNOPSIS
    rclone helper functions and aliases.

.DESCRIPTION
    Provides PowerShell functions and aliases for common rclone operations.
    Functions check for rclone availability using Test-CachedCommand for efficient
    command detection without triggering module autoload.

.NOTES
    Module: PowerShell.Profile.Rclone
    Author: PowerShell Profile
#>

# rclone copy - copy files to/from remote
<#
.SYNOPSIS
    Copies files using rclone.

.DESCRIPTION
    Wrapper for rclone copy command.

.PARAMETER Source
    Source path (local or remote).

.PARAMETER Destination
    Destination path (local or remote).

.EXAMPLE
    Copy-RcloneFile -Source "remote:path" -Destination "local:path"

.EXAMPLE
    Copy-RcloneFile -Source "local:path" -Destination "remote:path"
#>
function Copy-RcloneFile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$Source,
        
        [Parameter(Mandatory, Position = 1)]
        [string]$Destination
    )
    
    if (Test-CachedCommand rclone) {
        rclone copy $Source $Destination
    }
    else {
        Write-MissingToolWarning -Tool 'rclone' -InstallHint 'Install with: scoop install rclone'
    }
}

# rclone list - list remote files
<#
.SYNOPSIS
    Lists files using rclone.

.DESCRIPTION
    Wrapper for rclone ls command.

.PARAMETER Path
    Path to list (local or remote).

.EXAMPLE
    Get-RcloneFileList -Path "remote:path"

.EXAMPLE
    Get-RcloneFileList -Path "local:path"
#>
function Get-RcloneFileList {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$Path
    )
    
    if (Test-CachedCommand rclone) {
        rclone ls $Path
    }
    else {
        Write-MissingToolWarning -Tool 'rclone' -InstallHint 'Install with: scoop install rclone'
    }
}

# Create aliases for short forms
if (Get-Command -Name 'Set-AgentModeAlias' -ErrorAction SilentlyContinue) {
    Set-AgentModeAlias -Name 'rcopy' -Target 'Copy-RcloneFile'
    Set-AgentModeAlias -Name 'rls' -Target 'Get-RcloneFileList'
}
else {
    Set-Alias -Name 'rcopy' -Value 'Copy-RcloneFile' -ErrorAction SilentlyContinue
    Set-Alias -Name 'rls' -Value 'Get-RcloneFileList' -ErrorAction SilentlyContinue
}
