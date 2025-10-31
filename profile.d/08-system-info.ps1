# ===============================================
# 08-system-info.ps1
# System information helpers
# ===============================================

<#
.SYNOPSIS
    Shows system uptime.
.DESCRIPTION
    Calculates and displays the time elapsed since the system was last booted.
#>
function uptime {
    (Get-Date) - (Get-CimInstance -ClassName Win32_OperatingSystem).LastBootUpTime
}
<#
.SYNOPSIS
    Shows battery information.
.DESCRIPTION
    Displays battery status including charge remaining, battery status, and estimated runtime.
#>
function battery {
    Get-CimInstance -ClassName Win32_Battery | Select-Object Name, EstimatedChargeRemaining, BatteryStatus, EstimatedRunTime
}
<#
.SYNOPSIS
    Shows system information.
.DESCRIPTION
    Displays basic computer system information including name, manufacturer, model, and total memory.
#>
function sysinfo {
    Get-CimInstance -ClassName Win32_ComputerSystem | Select-Object Name, Manufacturer, Model, TotalPhysicalMemory
}
<#
.SYNOPSIS
    Shows CPU information.
.DESCRIPTION
    Displays processor information including name, number of cores, logical processors, and max clock speed.
#>
function cpuinfo {
    Get-CimInstance -ClassName Win32_Processor | Select-Object Name, NumberOfCores, NumberOfLogicalProcessors, MaxClockSpeed
}
<#
.SYNOPSIS
    Shows memory information.
.DESCRIPTION
    Displays total physical memory capacity in GB.
#>
function meminfo {
    Get-CimInstance -ClassName Win32_PhysicalMemory | Measure-Object -Property Capacity -Sum | Select-Object @{ Name = "TotalMemory(GB)"; Expression = { [math]::Round(($_.Sum / 1GB), 2) } }
}
