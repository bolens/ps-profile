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
#>
function Get-SystemUptime {
    (Get-Date) - (Get-CimInstance -ClassName Win32_OperatingSystem).LastBootUpTime
}
Set-AgentModeAlias -Name 'uptime' -Target 'Get-SystemUptime'
<#
.SYNOPSIS
    Shows battery information.
.DESCRIPTION
    Displays battery status including charge remaining, battery status, and estimated runtime.
#>
function Get-BatteryInfo {
    Get-CimInstance -ClassName Win32_Battery | Select-Object Name, EstimatedChargeRemaining, BatteryStatus, EstimatedRunTime
}
Set-AgentModeAlias -Name 'battery' -Target 'Get-BatteryInfo'
<#
.SYNOPSIS
    Shows system information.
.DESCRIPTION
    Displays basic computer system information including name, manufacturer, model, and total memory.
#>
function Get-SystemInfo {
    Get-CimInstance -ClassName Win32_ComputerSystem | Select-Object Name, Manufacturer, Model, TotalPhysicalMemory
}
Set-AgentModeAlias -Name 'sysinfo' -Target 'Get-SystemInfo'
<#
.SYNOPSIS
    Shows CPU information.
.DESCRIPTION
    Displays processor information including name, number of cores, logical processors, and max clock speed.
#>
function Get-CpuInfo {
    Get-CimInstance -ClassName Win32_Processor | Select-Object Name, NumberOfCores, NumberOfLogicalProcessors, MaxClockSpeed
}
Set-AgentModeAlias -Name 'cpuinfo' -Target 'Get-CpuInfo'
<#
.SYNOPSIS
    Shows memory information.
.DESCRIPTION
    Displays total physical memory capacity in GB.
#>
function Get-MemoryInfo {
    Get-CimInstance -ClassName Win32_PhysicalMemory | Measure-Object -Property Capacity -Sum | Select-Object @{ Name = "TotalMemory(GB)"; Expression = { [math]::Round(($_.Sum / 1GB), 2) } }
}
Set-AgentModeAlias -Name 'meminfo' -Target 'Get-MemoryInfo'