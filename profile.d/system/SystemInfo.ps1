# ===============================================
# SystemInfo.ps1
# System information utilities
# ===============================================

# Command location lookup (Unix 'which' equivalent)
<#
.SYNOPSIS
    Shows information about commands.
.DESCRIPTION
    Displays information about PowerShell commands and their locations.
#>
function Get-CommandInfo {
    param([Parameter(ValueFromRemainingArguments = $true)] $CommandArgs)

    if (-not $CommandArgs) {
        return $null
    }

    try {
        return Get-Command @CommandArgs -ErrorAction SilentlyContinue
    }
    catch {
        return $null
    }
}
Set-Alias -Name which -Value Get-CommandInfo -ErrorAction SilentlyContinue

# Disk space usage (Unix 'df' equivalent)
<#
.SYNOPSIS
    Shows disk usage information.
.DESCRIPTION
    Displays disk space usage (used, free, total) for all file system drives in GB.
#>
function Get-DiskUsage {
    try {
        Get-PSDrive -PSProvider FileSystem -ErrorAction Stop | Select-Object Name, @{ Name = "Used(GB)"; Expression = { [math]::Round(($_.Used / 1GB), 2) } }, @{ Name = "Free(GB)"; Expression = { [math]::Round(($_.Free / 1GB), 2) } }, @{ Name = "Total(GB)"; Expression = { [math]::Round((($_.Used + $_.Free) / 1GB), 2) } }, Root
    }
    catch {
        Write-Error "Failed to get disk usage information: $($_.Exception.Message)"
        throw
    }
}
Set-Alias -Name df -Value Get-DiskUsage -ErrorAction SilentlyContinue

# Top processes by CPU (Unix 'top' equivalent, aliased as 'htop')
<#
.SYNOPSIS
    Shows top CPU-consuming processes.
.DESCRIPTION
    Displays the top 10 processes sorted by CPU usage.
#>
function Get-TopProcesses {
    try {
        Get-Process -ErrorAction Stop | Sort-Object CPU -Descending | Select-Object -First 10
    }
    catch {
        Write-Error "Failed to get process information: $($_.Exception.Message)"
        throw
    }
}
Set-Alias -Name htop -Value Get-TopProcesses -ErrorAction SilentlyContinue

