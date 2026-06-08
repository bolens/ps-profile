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

.PARAMETER CommandArgs
    Command name and optional arguments passed to Get-Command.

.EXAMPLE
    Get-CommandInfo git

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
Set-AgentModeAlias -Name 'which' -Target 'Get-CommandInfo'
# Disk space usage (Unix 'df' equivalent)
<#
.SYNOPSIS
    Shows disk usage information.
.DESCRIPTION
    Displays disk space usage (used, free, total) for all file system drives in GB.
#>
function Get-DiskUsage {
    if (Get-Command Invoke-WithWideEvent -ErrorAction SilentlyContinue) {
        Invoke-WithWideEvent -OperationName 'systeminfo.disk-usage.get' -Context @{} -ScriptBlock {
            Get-PSDrive -PSProvider FileSystem -ErrorAction Stop | Select-Object Name, @{ Name = "Used(GB)"; Expression = { [math]::Round(($_.Used / 1GB), 2) } }, @{ Name = "Free(GB)"; Expression = { [math]::Round(($_.Free / 1GB), 2) } }, @{ Name = "Total(GB)"; Expression = { [math]::Round((($_.Used + $_.Free) / 1GB), 2) } }, Root
        }
    }
    else {
        try {
            Get-PSDrive -PSProvider FileSystem -ErrorAction Stop | Select-Object Name, @{ Name = "Used(GB)"; Expression = { [math]::Round(($_.Used / 1GB), 2) } }, @{ Name = "Free(GB)"; Expression = { [math]::Round(($_.Free / 1GB), 2) } }, @{ Name = "Total(GB)"; Expression = { [math]::Round((($_.Used + $_.Free) / 1GB), 2) } }, Root
        }
        catch {
            Write-Error "Failed to get disk usage information: $($_.Exception.Message)"
            throw
        }
    }
}
Set-AgentModeAlias -Name 'df' -Target 'Get-DiskUsage'
# Top processes by CPU (Unix 'top' equivalent, aliased as 'htop')
<#
.SYNOPSIS
    Shows top CPU-consuming processes.
.DESCRIPTION
    Displays the top 10 processes sorted by CPU usage.
#>
function Get-TopProcesses {
    if (Get-Command Invoke-WithWideEvent -ErrorAction SilentlyContinue) {
        Invoke-WithWideEvent -OperationName 'systeminfo.top-processes.get' -Context @{} -ScriptBlock {
            Get-Process -ErrorAction Stop | Sort-Object CPU -Descending | Select-Object -First 10
        }
    }
    else {
        try {
            Get-Process -ErrorAction Stop | Sort-Object CPU -Descending | Select-Object -First 10
        }
        catch {
            Write-Error "Failed to get process information: $($_.Exception.Message)"
            throw
        }
    }
}
Set-AgentModeAlias -Name 'htop' -Target 'Get-TopProcesses'