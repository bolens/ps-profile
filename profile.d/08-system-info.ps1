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
function battery {
    <#
    .SYNOPSIS
        Shows battery information.
    .DESCRIPTION
        Displays battery status including charge remaining, battery status, and estimated runtime.
    #>
    Get-CimInstance -ClassName Win32_Battery | Select-Object Name, EstimatedChargeRemaining, BatteryStatus, EstimatedRunTime
}
function sysinfo {
    <#
    .SYNOPSIS
        Shows system information.
    .DESCRIPTION
        Displays basic computer system information including name, manufacturer, model, and total memory.
    #>
    Get-CimInstance -ClassName Win32_ComputerSystem | Select-Object Name, Manufacturer, Model, TotalPhysicalMemory
}
function cpuinfo {
    <#
    .SYNOPSIS
        Shows CPU information.
    .DESCRIPTION
        Displays processor information including name, number of cores, logical processors, and max clock speed.
    #>
    Get-CimInstance -ClassName Win32_Processor | Select-Object Name, NumberOfCores, NumberOfLogicalProcessors, MaxClockSpeed
}
function meminfo {
    <#
    .SYNOPSIS
        Shows memory information.
    .DESCRIPTION
        Displays total physical memory capacity in GB.
    #>
    Get-CimInstance -ClassName Win32_PhysicalMemory | Measure-Object -Property Capacity -Sum | Select-Object @{ Name = "TotalMemory(GB)"; Expression = { [math]::Round(($_.Sum / 1GB), 2) } }
}

























