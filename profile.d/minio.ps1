# ===============================================
# minio.ps1
# MinIO client helpers (mc) — guarded
# ===============================================
# Tier: essential
# Dependencies: bootstrap, env

<#
.SYNOPSIS
    MinIO client helper functions and aliases.

.DESCRIPTION
    Provides PowerShell functions and aliases for common MinIO client operations.
    Functions check for mc availability using Test-CachedCommand for efficient
    command detection without triggering module autoload.

.NOTES
    Module: PowerShell.Profile.Minio
    Author: PowerShell Profile
#>

# MinIO list - list files in MinIO
<#
.SYNOPSIS
    Lists files in MinIO storage.

.DESCRIPTION
    Wrapper for mc ls command.

.PARAMETER Path
    Path to list in MinIO.

.EXAMPLE
    Get-MinioFileList -Path "myminio/bucket/path"

.EXAMPLE
    Get-MinioFileList -Path "myminio/bucket/"
#>
function Get-MinioFileList {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$Path
    )
    
    if (Test-CachedCommand mc) {
        mc ls $Path
    }
    else {
        Write-MissingToolWarning -Tool 'mc' -InstallHint 'Install with: scoop install minio-client'
    }
}

# MinIO copy - copy files to/from MinIO
<#
.SYNOPSIS
    Copies files using MinIO client.

.DESCRIPTION
    Wrapper for mc cp command.

.PARAMETER Source
    Source path (local or MinIO).

.PARAMETER Destination
    Destination path (local or MinIO).

.EXAMPLE
    Copy-MinioFile -Source "local/file.txt" -Destination "myminio/bucket/file.txt"

.EXAMPLE
    Copy-MinioFile -Source "myminio/bucket/file.txt" -Destination "local/file.txt"
#>
function Copy-MinioFile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$Source,
        
        [Parameter(Mandatory, Position = 1)]
        [string]$Destination
    )
    
    if (Test-CachedCommand mc) {
        mc cp $Source $Destination
    }
    else {
        Write-MissingToolWarning -Tool 'mc' -InstallHint 'Install with: scoop install minio-client'
    }
}

# Create aliases for short forms
if (Get-Command -Name 'Set-AgentModeAlias' -ErrorAction SilentlyContinue) {
    Set-AgentModeAlias -Name 'mc-ls' -Target 'Get-MinioFileList'
    Set-AgentModeAlias -Name 'mc-cp' -Target 'Copy-MinioFile'
}
else {
    Set-Alias -Name 'mc-ls' -Value 'Get-MinioFileList' -ErrorAction SilentlyContinue
    Set-Alias -Name 'mc-cp' -Value 'Copy-MinioFile' -ErrorAction SilentlyContinue
}
