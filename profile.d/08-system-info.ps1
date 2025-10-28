# ===============================================
# 08-system-info.ps1
# System information helpers
# ===============================================

function uptime { (Get-Date) - (Get-CimInstance -ClassName Win32_OperatingSystem).LastBootUpTime }
function battery { Get-CimInstance -ClassName Win32_Battery | Select-Object Name,EstimatedChargeRemaining,BatteryStatus,EstimatedRunTime }
function sysinfo { Get-CimInstance -ClassName Win32_ComputerSystem | Select-Object Name,Manufacturer,Model,TotalPhysicalMemory }
function cpuinfo { Get-CimInstance -ClassName Win32_Processor | Select-Object Name,NumberOfCores,NumberOfLogicalProcessors,MaxClockSpeed }
function meminfo { Get-CimInstance -ClassName Win32_PhysicalMemory | Measure-Object -Property Capacity -Sum | Select-Object @{ Name = "TotalMemory(GB)"; Expression = { [math]::Round(($_.Sum / 1GB),2) } } }







