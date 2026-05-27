# ===============================================
# system-info.ps1
# System information helpers
# ===============================================
# Tier: essential
# Dependencies: bootstrap, env
# Environment: server, development

<#
.SYNOPSIS
    Shows system uptime.
.DESCRIPTION
    Calculates and displays the time elapsed since the system was last booted.
    On Windows uses Win32_OperatingSystem; on Linux reads /proc/uptime; on macOS uses sysctl.
#>
function Get-SystemUptime {
    if ($IsWindows -or $PSVersionTable.Platform -eq 'Win32NT') {
        (Get-Date) - (Get-CimInstance -ClassName Win32_OperatingSystem).LastBootUpTime
    }
    elseif ($IsMacOS) {
        $boottime = & sysctl -n kern.boottime 2>/dev/null
        if ($boottime -match 'sec = (\d+)') {
            (Get-Date) - [DateTimeOffset]::FromUnixTimeSeconds([long]$Matches[1]).LocalDateTime
        }
    }
    else {
        # Linux: /proc/uptime contains seconds since boot
        if (Test-Path '/proc/uptime') {
            $uptimeSecs = [double](Get-Content '/proc/uptime').Split(' ')[0]
            [TimeSpan]::FromSeconds($uptimeSecs)
        }
        elseif (Test-CachedCommand 'uptime') {
            & uptime
        }
        else {
            Write-Warning 'Cannot determine uptime on this platform.'
        }
    }
}
Set-AgentModeAlias -Name 'uptime' -Target 'Get-SystemUptime'
<#
.SYNOPSIS
    Shows battery information.
.DESCRIPTION
    Displays battery status including charge remaining, battery status, and estimated runtime.
    On Windows uses Win32_Battery; on Linux reads /sys/class/power_supply.
#>
function Get-BatteryInfo {
    if ($IsWindows -or $PSVersionTable.Platform -eq 'Win32NT') {
        Get-CimInstance -ClassName Win32_Battery | Select-Object Name, EstimatedChargeRemaining, BatteryStatus, EstimatedRunTime
    }
    else {
        # Linux/macOS: read from sysfs
        $batteries = Get-ChildItem '/sys/class/power_supply' -ErrorAction SilentlyContinue |
            Where-Object { (Get-Content (Join-Path $_.FullName 'type') -ErrorAction SilentlyContinue) -eq 'Battery' }
        if ($batteries) {
            foreach ($bat in $batteries) {
                $cap  = Get-Content (Join-Path $bat.FullName 'capacity') -ErrorAction SilentlyContinue
                $stat = Get-Content (Join-Path $bat.FullName 'status')   -ErrorAction SilentlyContinue
                [PSCustomObject]@{
                    Name                     = $bat.Name
                    EstimatedChargeRemaining = if ($cap) { [int]$cap } else { $null }
                    BatteryStatus            = $stat
                    EstimatedRunTime         = 'N/A'
                }
            }
        }
        else {
            Write-Warning 'No battery information available on this system.'
        }
    }
}
Set-AgentModeAlias -Name 'battery' -Target 'Get-BatteryInfo'
<#
.SYNOPSIS
    Shows system information.
.DESCRIPTION
    Displays basic computer system information including name, manufacturer, model, and total memory.
    On Windows uses Win32_ComputerSystem; on Linux reads /proc/meminfo and dmidecode where available.
#>
function Get-SystemInfo {
    if ($IsWindows -or $PSVersionTable.Platform -eq 'Win32NT') {
        Get-CimInstance -ClassName Win32_ComputerSystem | Select-Object Name, Manufacturer, Model, TotalPhysicalMemory
    }
    else {
        $totalMem = $null
        if (Test-Path '/proc/meminfo') {
            $memLine = Select-String -Path '/proc/meminfo' -Pattern '^MemTotal:\s+(\d+)' | Select-Object -First 1
            if ($memLine) { $totalMem = [long]$memLine.Matches[0].Groups[1].Value * 1KB }
        }
        [PSCustomObject]@{
            Name               = [System.Net.Dns]::GetHostName()
            Manufacturer       = (Get-Content '/sys/class/dmi/id/sys_vendor'   -ErrorAction SilentlyContinue) ?? 'Unknown'
            Model              = (Get-Content '/sys/class/dmi/id/product_name' -ErrorAction SilentlyContinue) ?? 'Unknown'
            TotalPhysicalMemory = $totalMem
        }
    }
}
Set-AgentModeAlias -Name 'sysinfo' -Target 'Get-SystemInfo'
<#
.SYNOPSIS
    Shows CPU information.
.DESCRIPTION
    Displays processor information including name, number of cores, logical processors, and max clock speed.
    On Windows uses Win32_Processor; on Linux reads /proc/cpuinfo.
#>
function Get-CpuInfo {
    if ($IsWindows -or $PSVersionTable.Platform -eq 'Win32NT') {
        Get-CimInstance -ClassName Win32_Processor | Select-Object Name, NumberOfCores, NumberOfLogicalProcessors, MaxClockSpeed
    }
    else {
        $cpuinfo = Get-Content '/proc/cpuinfo' -ErrorAction SilentlyContinue
        if ($cpuinfo) {
            $modelName   = ($cpuinfo | Select-String '^model name\s*:(.+)' | Select-Object -First 1)?.Matches[0]?.Groups[1]?.Value?.Trim()
            $physCores   = ($cpuinfo | Select-String '^cpu cores\s*:(.+)'  | Select-Object -First 1)?.Matches[0]?.Groups[1]?.Value?.Trim()
            $logicalProc = ($cpuinfo | Select-String '^processor\s*:'      | Measure-Object).Count
            $maxMHz      = ($cpuinfo | Select-String '^cpu MHz\s*:(.+)'    | ForEach-Object { [double]$_.Matches[0].Groups[1].Value } | Measure-Object -Maximum).Maximum
            [PSCustomObject]@{
                Name                      = $modelName ?? 'Unknown'
                NumberOfCores             = if ($physCores) { [int]$physCores } else { $null }
                NumberOfLogicalProcessors = $logicalProc
                MaxClockSpeed             = if ($maxMHz) { [int]$maxMHz } else { $null }
            }
        }
        elseif ($IsMacOS) {
            [PSCustomObject]@{
                Name                      = (& sysctl -n machdep.cpu.brand_string 2>/dev/null)
                NumberOfCores             = (& sysctl -n hw.physicalcpu 2>/dev/null)
                NumberOfLogicalProcessors = (& sysctl -n hw.logicalcpu 2>/dev/null)
                MaxClockSpeed             = $null
            }
        }
        else {
            Write-Warning 'Cannot retrieve CPU info on this platform.'
        }
    }
}
Set-AgentModeAlias -Name 'cpuinfo' -Target 'Get-CpuInfo'
<#
.SYNOPSIS
    Shows memory information.
.DESCRIPTION
    Displays total physical memory capacity in GB.
    On Windows uses Win32_PhysicalMemory; on Linux reads /proc/meminfo.
#>
function Get-MemoryInfo {
    if ($IsWindows -or $PSVersionTable.Platform -eq 'Win32NT') {
        Get-CimInstance -ClassName Win32_PhysicalMemory | Measure-Object -Property Capacity -Sum |
            Select-Object @{ Name = 'TotalMemory(GB)'; Expression = { [math]::Round(($_.Sum / 1GB), 2) } }
    }
    else {
        if (Test-Path '/proc/meminfo') {
            $memLines = Get-Content '/proc/meminfo'
            $total     = ($memLines | Select-String '^MemTotal:\s+(\d+)')?.Matches[0]?.Groups[1]?.Value
            $available = ($memLines | Select-String '^MemAvailable:\s+(\d+)')?.Matches[0]?.Groups[1]?.Value
            [PSCustomObject]@{
                'TotalMemory(GB)'     = if ($total)     { [math]::Round([long]$total     * 1KB / 1GB, 2) } else { $null }
                'AvailableMemory(GB)' = if ($available) { [math]::Round([long]$available * 1KB / 1GB, 2) } else { $null }
            }
        }
        elseif ($IsMacOS) {
            $memBytes = (& sysctl -n hw.memsize 2>/dev/null)
            [PSCustomObject]@{ 'TotalMemory(GB)' = if ($memBytes) { [math]::Round([long]$memBytes / 1GB, 2) } else { $null } }
        }
        else {
            Write-Warning 'Cannot retrieve memory info on this platform.'
        }
    }
}
Set-AgentModeAlias -Name 'meminfo' -Target 'Get-MemoryInfo'
