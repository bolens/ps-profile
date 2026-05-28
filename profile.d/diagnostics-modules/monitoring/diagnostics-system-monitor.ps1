# ===============================================
# System monitoring diagnostic functions
# System dashboard, CPU, memory, disk, and network monitoring
# ===============================================

<#
System monitoring dashboard for PowerShell profile.
Provides quick overview of CPU, memory, disk, and network status.
#>

# Import Locale module
$localeModulePath = Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'lib' 'core' 'Locale.psm1'
if ($localeModulePath -and -not [string]::IsNullOrWhiteSpace($localeModulePath) -and (Test-Path -LiteralPath $localeModulePath)) {
    Import-Module $localeModulePath -DisableNameChecking -ErrorAction SilentlyContinue
}

try {
    if ($null -ne (Get-Variable -Name 'SystemMonitorLoaded' -Scope Global -ErrorAction SilentlyContinue)) { return }

    # -----------------------------------------------------------------------
    # Private cross-platform data helpers — used by all display functions below
    # -----------------------------------------------------------------------
    function script:Get-XPlatCpuInfo {
        if ($IsWindows -or $PSVersionTable.Platform -eq 'Win32NT') {
            return Get-CimInstance Win32_Processor -ErrorAction Stop
        }
        $cpuinfo = Get-Content '/proc/cpuinfo' -ErrorAction SilentlyContinue
        if ($IsMacOS) {
            return [PSCustomObject]@{
                Name                      = (& sysctl -n machdep.cpu.brand_string 2>/dev/null)
                Manufacturer              = (& sysctl -n machdep.cpu.vendor      2>/dev/null)
                MaxClockSpeed             = $null
                NumberOfCores             = [int](& sysctl -n hw.physicalcpu 2>/dev/null)
                NumberOfLogicalProcessors = [int](& sysctl -n hw.logicalcpu  2>/dev/null)
                Architecture              = 'arm64/x86_64'
            }
        }
        if ($cpuinfo) {
            $modelName   = ($cpuinfo | Select-String '^model name\s*:(.+)' | Select-Object -First 1)?.Matches[0]?.Groups[1]?.Value?.Trim()
            $vendor      = ($cpuinfo | Select-String '^vendor_id\s*:(.+)'  | Select-Object -First 1)?.Matches[0]?.Groups[1]?.Value?.Trim()
            $physCores   = ($cpuinfo | Select-String '^cpu cores\s*:(.+)'  | Select-Object -First 1)?.Matches[0]?.Groups[1]?.Value?.Trim()
            $logicalProc = ($cpuinfo | Select-String '^processor\s*:'      | Measure-Object).Count
            $maxMHz      = ($cpuinfo | Select-String '^cpu MHz\s*:(.+)'    | ForEach-Object { [double]$_.Matches[0].Groups[1].Value } | Measure-Object -Maximum).Maximum
            return [PSCustomObject]@{
                Name                      = $modelName ?? 'Unknown'
                Manufacturer              = $vendor    ?? 'Unknown'
                MaxClockSpeed             = if ($maxMHz) { [int]$maxMHz } else { $null }
                NumberOfCores             = if ($physCores) { [int]$physCores } else { $logicalProc }
                NumberOfLogicalProcessors = $logicalProc
                Architecture              = (& uname -m 2>/dev/null)
            }
        }
        return $null
    }

    function script:Get-XPlatCpuUsage {
        if ($IsWindows -or $PSVersionTable.Platform -eq 'Win32NT') {
            return (Get-Counter '\Processor(_Total)\% Processor Time' -SampleInterval 1 -MaxSamples 1 -ErrorAction Stop).CounterSamples.CookedValue
        }
        if (Test-Path '/proc/stat') {
            # Two-sample delta for accurate idle %
            $s1 = (Get-Content '/proc/stat')[0] -split '\s+' | Select-Object -Skip 1 | ForEach-Object { [long]$_ }
            Start-Sleep -Milliseconds 200
            $s2 = (Get-Content '/proc/stat')[0] -split '\s+' | Select-Object -Skip 1 | ForEach-Object { [long]$_ }
            $idle1 = $s1[3]; $total1 = ($s1 | Measure-Object -Sum).Sum
            $idle2 = $s2[3]; $total2 = ($s2 | Measure-Object -Sum).Sum
            $dTotal = $total2 - $total1; $dIdle  = $idle2  - $idle1
            if ($dTotal -gt 0) { return [math]::Round((1 - $dIdle / $dTotal) * 100, 1) }
        }
        return $null
    }

    function script:Get-XPlatMemoryInfo {
        if ($IsWindows -or $PSVersionTable.Platform -eq 'Win32NT') {
            return Get-CimInstance Win32_OperatingSystem -ErrorAction Stop
        }
        if ($IsMacOS) {
            $total = [long](& sysctl -n hw.memsize 2>/dev/null)
            # vm_stat gives pages; page size typically 4096
            $vmstat = & vm_stat 2>/dev/null
            $free   = ([long]($vmstat | Select-String 'Pages free:\s+(\d+)' | ForEach-Object { $_.Matches[0].Groups[1].Value }) + 0) * 4096
            return [PSCustomObject]@{
                TotalVisibleMemorySize = [long]($total / 1KB)
                FreePhysicalMemory     = [long]($free  / 1KB)
                LastBootUpTime         = $null  # macOS: set separately if needed
            }
        }
        if (Test-Path '/proc/meminfo') {
            $lines   = Get-Content '/proc/meminfo'
            $total   = [long]($lines | Select-String '^MemTotal:\s+(\d+)'     | ForEach-Object { $_.Matches[0].Groups[1].Value })
            $avail   = [long]($lines | Select-String '^MemAvailable:\s+(\d+)' | ForEach-Object { $_.Matches[0].Groups[1].Value })
            # Approximate LastBootUpTime from /proc/uptime
            $bootTime = $null
            if (Test-Path '/proc/uptime') {
                $uptimeSecs = [double](Get-Content '/proc/uptime').Split(' ')[0]
                $bootTime   = (Get-Date).AddSeconds(-$uptimeSecs)
            }
            return [PSCustomObject]@{
                TotalVisibleMemorySize = $total
                FreePhysicalMemory     = $avail
                LastBootUpTime         = $bootTime
            }
        }
        return $null
    }

    function script:Get-XPlatDiskInfo {
        if ($IsWindows -or $PSVersionTable.Platform -eq 'Win32NT') {
            return Get-CimInstance Win32_LogicalDisk | Where-Object { $_.DriveType -eq 3 }
        }
        # Linux/macOS: use df -P for POSIX output (bytes via -k for KB)
        $dfLines = (& df -Pk 2>/dev/null) | Select-Object -Skip 1
        $drives = foreach ($line in $dfLines) {
            $parts = $line -split '\s+'
            if ($parts.Count -ge 6) {
                $totalKB = [long]$parts[1]; $usedKB = [long]$parts[2]; $freeKB = [long]$parts[3]
                $mountPoint = $parts[5]
                # Skip tmpfs, devtmpfs, overlay etc — only physical/network mounts
                if ($parts[0] -notmatch '^(tmpfs|devtmpfs|overlay|none|udev|cgroupfs|cgroup|proc|sysfs|devpts)') {
                    [PSCustomObject]@{
                        DeviceID   = $mountPoint
                        FileSystem = 'N/A'
                        Size       = $totalKB * 1KB
                        FreeSpace  = $freeKB  * 1KB
                    }
                }
            }
        }
        return $drives
    }

    function script:Get-XPlatRootDisk {
        # Returns a single disk object for the root/system drive (C: on Windows, / on Linux)
        if ($IsWindows -or $PSVersionTable.Platform -eq 'Win32NT') {
            return Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='C:'" -ErrorAction SilentlyContinue
        }
        return Get-XPlatDiskInfo | Where-Object { $_.DeviceID -eq '/' } | Select-Object -First 1
    }
    # -----------------------------------------------------------------------
    <#
    .SYNOPSIS
        Shows a comprehensive system status dashboard.
    .DESCRIPTION
        Displays CPU usage, memory usage, disk space, network status,
        and other system metrics in a clean, organized format.
    #>
    function Show-SystemDashboard {
        $debugLevel = Get-ProfileDebugLevel
        if ($debugLevel -ge 1) {
            Write-Verbose "[diagnostics.system-monitor] Showing system dashboard"
        }

        $dashboardStartTime = [DateTime]::Now
        Write-Host "🖥️  System Dashboard" -ForegroundColor Cyan
        Write-Host "==================" -ForegroundColor Cyan

        # CPU Information
        Write-Host "`n🧠 CPU Information:" -ForegroundColor Yellow
        try {
            $cpuStartTime = [DateTime]::Now
            $cpu = Get-XPlatCpuInfo
            try {
                $cpuUsage = Get-XPlatCpuUsage
                $cpuPercentStr = if (Get-Command Format-LocaleNumber -ErrorAction SilentlyContinue) {
                    Format-LocaleNumber $cpuUsage -Format 'N1'
                }
                else {
                    $cpuUsage.ToString("N1")
                }
                Write-Host ("  Usage: {0}%" -f $cpuPercentStr)
                if ($debugLevel -ge 3) {
                    $cpuDuration = ([DateTime]::Now - $cpuStartTime).TotalMilliseconds
                    Write-Host "  [diagnostics.system-monitor] CPU info retrieved in ${cpuDuration}ms" -ForegroundColor DarkGray
                }
            }
            catch {
                if ($debugLevel -ge 1) {
                    if (Get-Command Write-StructuredWarning -ErrorAction SilentlyContinue) {
                        Write-StructuredWarning -Message "Unable to retrieve CPU usage" -OperationName 'diagnostics.system-monitor.cpu' -Context @{
                            error = $_.Exception.Message
                        } -Code 'CPU_USAGE_UNAVAILABLE'
                    }
                }
                Write-Host "  Usage: Unable to retrieve CPU usage" -ForegroundColor Yellow
                if ($debugLevel -ge 2) {
                    Write-Verbose "[diagnostics.system-monitor] CPU usage retrieval failed: $($_.Exception.Message)"
                }
            }
            Write-Host ("  Model: {0}" -f $cpu.Name)
            Write-Host ("  Cores: {0} physical, {1} logical" -f $cpu.NumberOfCores, $cpu.NumberOfLogicalProcessors)
        }
        catch [System.Management.ManagementException] {
            if ($debugLevel -ge 1) {
                if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                    Write-StructuredError -ErrorRecord $_ -OperationName 'diagnostics.system-monitor.cpu' -Context @{
                        error_type = 'WMI/CIM'
                    }
                }
            }
            Write-Host "  CPU info unavailable (WMI/CIM error)" -ForegroundColor Red
            if ($debugLevel -ge 2) {
                Write-Verbose "[diagnostics.system-monitor] CPU info unavailable (WMI/CIM error): $($_.Exception.Message)"
            }
        }
        catch {
            if ($debugLevel -ge 1) {
                if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                    Write-StructuredError -ErrorRecord $_ -OperationName 'diagnostics.system-monitor.cpu' -Context @{
                        error_type = 'General'
                    }
                }
            }
            Write-Host "  CPU info unavailable: $($_.Exception.Message)" -ForegroundColor Red
            if ($debugLevel -ge 2) {
                Write-Verbose "[diagnostics.system-monitor] CPU info error: $($_.Exception.Message)"
            }
        }

        # Memory Information
        Write-Host "`n💾 Memory Information:" -ForegroundColor Green
        try {
            $memory = Get-XPlatMemoryInfo
            $totalMemory = [math]::Round($memory.TotalVisibleMemorySize / 1MB, 1)
            $freeMemory = [math]::Round($memory.FreePhysicalMemory / 1MB, 1)
            $usedMemory = $totalMemory - $freeMemory
            $memoryUsagePercent = [math]::Round(($usedMemory / $totalMemory) * 100, 1)

            $totalMemoryStr = if (Get-Command Format-LocaleNumber -ErrorAction SilentlyContinue) {
                Format-LocaleNumber $totalMemory -Format 'N1'
            }
            else {
                $totalMemory.ToString("N1")
            }
            $usedMemoryStr = if (Get-Command Format-LocaleNumber -ErrorAction SilentlyContinue) {
                Format-LocaleNumber $usedMemory -Format 'N1'
            }
            else {
                $usedMemory.ToString("N1")
            }
            $freeMemoryStr = if (Get-Command Format-LocaleNumber -ErrorAction SilentlyContinue) {
                Format-LocaleNumber $freeMemory -Format 'N1'
            }
            else {
                $freeMemory.ToString("N1")
            }
            $memoryPercentStr = if (Get-Command Format-LocaleNumber -ErrorAction SilentlyContinue) {
                Format-LocaleNumber $memoryUsagePercent -Format 'N1'
            }
            else {
                $memoryUsagePercent.ToString("N1")
            }
            Write-Host ("  Total: {0} GB" -f $totalMemoryStr)
            Write-Host ("  Used:  {0} GB ({1}%)" -f $usedMemoryStr, $memoryPercentStr)
            Write-Host ("  Free:  {0} GB" -f $freeMemoryStr)

            # Color coding for memory usage
            $color = if ($memoryUsagePercent -gt 90) { "Red" } elseif ($memoryUsagePercent -gt 75) { "Yellow" } else { "Green" }
            Write-Host ("  Status: {0}" -f $(if ($memoryUsagePercent -gt 90) { "Critical" } elseif ($memoryUsagePercent -gt 75) { "High" } else { "Normal" })) -ForegroundColor $color
        }
        catch {
            if ($debugLevel -ge 1) {
                if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                    Write-StructuredError -ErrorRecord $_ -OperationName 'diagnostics.system-monitor.memory' -Context @{}
                }
            }
            Write-Host "  Memory info unavailable" -ForegroundColor Red
            if ($debugLevel -ge 2) {
                Write-Verbose "[diagnostics.system-monitor] Memory info error: $($_.Exception.Message)"
            }
        }

        # Disk Information
        Write-Host "`n💿 Disk Information:" -ForegroundColor Magenta
        try {
            $drives = Get-XPlatDiskInfo # Fixed/physical drives only
            foreach ($drive in $drives) {
                $totalSpace = [math]::Round($drive.Size / 1GB, 1)
                $freeSpace = [math]::Round($drive.FreeSpace / 1GB, 1)
                $usedSpace = $totalSpace - $freeSpace
                $usagePercent = [math]::Round(($usedSpace / $totalSpace) * 100, 1)

                $usedSpaceStr = if (Get-Command Format-LocaleNumber -ErrorAction SilentlyContinue) {
                    Format-LocaleNumber $usedSpace -Format 'N1'
                }
                else {
                    $usedSpace.ToString("N1")
                }
                $totalSpaceStr = if (Get-Command Format-LocaleNumber -ErrorAction SilentlyContinue) {
                    Format-LocaleNumber $totalSpace -Format 'N1'
                }
                else {
                    $totalSpace.ToString("N1")
                }
                $usagePercentStr = if (Get-Command Format-LocaleNumber -ErrorAction SilentlyContinue) {
                    Format-LocaleNumber $usagePercent -Format 'N1'
                }
                else {
                    $usagePercent.ToString("N1")
                }
                Write-Host ("  {0}: {1} GB used of {2} GB ({3}%)" -f $drive.DeviceID, $usedSpaceStr, $totalSpaceStr, $usagePercentStr)

                # Color coding for disk usage
                $color = if ($usagePercent -gt 95) { "Red" } elseif ($usagePercent -gt 85) { "Yellow" } else { "Green" }
                Write-Host ("      Status: {0}" -f $(if ($usagePercent -gt 95) { "Critical" } elseif ($usagePercent -gt 85) { "Warning" } else { "OK" })) -ForegroundColor $color
            }
        }
        catch {
            if ($debugLevel -ge 1) {
                if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                    Write-StructuredError -ErrorRecord $_ -OperationName 'diagnostics.system-monitor.disk' -Context @{}
                }
            }
            Write-Host "  Disk info unavailable" -ForegroundColor Red
            if ($debugLevel -ge 2) {
                Write-Verbose "[diagnostics.system-monitor] Disk info error: $($_.Exception.Message)"
            }
        }

        # Network Information
        Write-Host "`n🌐 Network Information:" -ForegroundColor Blue
        try {
            $networks = Get-NetAdapter | Where-Object { $_.Status -eq "Up" }
            if ($networks) {
                foreach ($network in $networks) {
                    Write-Host ("  {0}: {1}" -f $network.Name, $network.Status)
                    $ipAddresses = Get-NetIPAddress -InterfaceAlias $network.Name -AddressFamily IPv4 -ErrorAction SilentlyContinue
                    if ($ipAddresses) {
                        $ipAddresses | ForEach-Object {
                            Write-Host ("    IPv4: {0}" -f $_.IPAddress)
                        }
                    }
                }
            }
            else {
                Write-Host "  No active network adapters" -ForegroundColor Yellow
            }

            # Internet connectivity check
            Write-Host "`n🌍 Internet Connectivity:" -ForegroundColor Cyan
            try {
                $pingTarget = '8.8.8.8'
                $ping = Test-Connection -ComputerName $pingTarget -Count 1 -TimeoutSeconds 2 -ErrorAction Stop
                Write-Host ("  Ping to Google DNS: {0}ms" -f $ping.ResponseTime) -ForegroundColor Green
            }
            catch {
                Write-Host "  Internet connectivity check failed" -ForegroundColor Red
            }
        }
        catch {
            if ($debugLevel -ge 1) {
                if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                    Write-StructuredError -ErrorRecord $_ -OperationName 'diagnostics.system-monitor.network' -Context @{}
                }
            }
            Write-Host "  Network info unavailable" -ForegroundColor Red
            if ($debugLevel -ge 2) {
                Write-Verbose "[diagnostics.system-monitor] Network info error: $($_.Exception.Message)"
            }
        }

        # System Uptime
        Write-Host "`n⏰ System Uptime:" -ForegroundColor White
        try {
            $_mem = Get-XPlatMemoryInfo
            $uptime = if ($_mem?.LastBootUpTime) { (Get-Date) - $_mem.LastBootUpTime } else { $null }
            $daysStr = if (Get-Command Format-LocaleNumber -ErrorAction SilentlyContinue) {
                Format-LocaleNumber $uptime.Days -Format 'N0'
            }
            else {
                $uptime.Days.ToString("N0")
            }
            $hoursStr = if (Get-Command Format-LocaleNumber -ErrorAction SilentlyContinue) {
                Format-LocaleNumber $uptime.Hours -Format 'N0'
            }
            else {
                $uptime.Hours.ToString("N0")
            }
            $minutesStr = if (Get-Command Format-LocaleNumber -ErrorAction SilentlyContinue) {
                Format-LocaleNumber $uptime.Minutes -Format 'N0'
            }
            else {
                $uptime.Minutes.ToString("N0")
            }
            Write-Host ("  {0} days, {1} hours, {2} minutes" -f $daysStr, $hoursStr, $minutesStr)
        }
        catch {
            if ($debugLevel -ge 1) {
                if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                    Write-StructuredError -ErrorRecord $_ -OperationName 'diagnostics.system-monitor.uptime' -Context @{}
                }
            }
            Write-Host "  Uptime info unavailable" -ForegroundColor Red
            if ($debugLevel -ge 2) {
                Write-Verbose "[diagnostics.system-monitor] Uptime info error: $($_.Exception.Message)"
            }
        }

        # PowerShell Session Info
        Write-Host "`n💻 PowerShell Session:" -ForegroundColor Gray
        Write-Host ("  Version: {0}" -f $PSVersionTable.PSVersion)
        Write-Host ("  Edition: {0}" -f $PSVersionTable.PSEdition)
        Write-Host ("  Profile loaded: {0}" -f $(if ($global:PSProfileStartTime) { "Yes" } else { "No" }))

        if ($global:PSProfileStartTime) {
            $profileUptime = (Get-Date) - $global:PSProfileStartTime
            $uptimeStr = if (Get-Command Format-LocaleNumber -ErrorAction SilentlyContinue) {
                Format-LocaleNumber $profileUptime.TotalMinutes -Format 'N1'
            }
            else {
                $profileUptime.TotalMinutes.ToString("N1")
            }
            Write-Host ("  Profile uptime: {0} minutes" -f $uptimeStr)
        }

        $totalDuration = ([DateTime]::Now - $dashboardStartTime).TotalMilliseconds
        if ($debugLevel -ge 2) {
            Write-Verbose "[diagnostics.system-monitor] System dashboard completed in ${totalDuration}ms"
        }
        if ($debugLevel -ge 3) {
            Write-Host "  [diagnostics.system-monitor] Dashboard generation time: ${totalDuration}ms" -ForegroundColor DarkGray
        }
    }

    # Quick system status (compact version)
    <#
    .SYNOPSIS
        Shows a compact system status overview.
    .DESCRIPTION
        Displays essential system metrics in a compact format for quick checking.
    #>
    function Show-SystemStatus {
        try {
            # CPU
            $cpuUsage = try { Get-XPlatCpuUsage } catch { $null }
            $cpuColor = if ($cpuUsage -gt 80) { "Red" } elseif ($cpuUsage -gt 60) { "Yellow" } else { "Green" }

            # Memory
            $memory = try { Get-XPlatMemoryInfo } catch { $null }
            if ($memory) {
                $totalMemory = $memory.TotalVisibleMemorySize / 1MB
                $freeMemory = $memory.FreePhysicalMemory / 1MB
                $memoryUsagePercent = (($totalMemory - $freeMemory) / $totalMemory) * 100
                $memoryColor = if ($memoryUsagePercent -gt 90) { "Red" } elseif ($memoryUsagePercent -gt 75) { "Yellow" } else { "Green" }
            }

            # Disk (C: drive)
            $disk = try { Get-XPlatRootDisk } catch { $null }
            if ($disk -and $disk.Size -gt 0) {
                $diskUsagePercent = (($disk.Size - $disk.FreeSpace) / $disk.Size) * 100
                $diskColor = if ($diskUsagePercent -gt 95) { "Red" } elseif ($diskUsagePercent -gt 85) { "Yellow" } else { "Green" }
            }

            Write-Host "🖥️ System Status:" -ForegroundColor Cyan -NoNewline
            $cpuPercentStr = if (Get-Command Format-LocaleNumber -ErrorAction SilentlyContinue) {
                Format-LocaleNumber $cpuUsage -Format 'N0'
            }
            else {
                $cpuUsage.ToString("N0")
            }
            Write-Host (" CPU: {0}%" -f $cpuPercentStr) -ForegroundColor $cpuColor -NoNewline
            if ($memory) {
                $memoryPercentStr = if (Get-Command Format-LocaleNumber -ErrorAction SilentlyContinue) {
                    Format-LocaleNumber $memoryUsagePercent -Format 'N0'
                }
                else {
                    $memoryUsagePercent.ToString("N0")
                }
                Write-Host (" | RAM: {0}%" -f $memoryPercentStr) -ForegroundColor $memoryColor -NoNewline
            }
            if ($disk) {
                $diskPercentStr = if (Get-Command Format-LocaleNumber -ErrorAction SilentlyContinue) {
                    Format-LocaleNumber $diskUsagePercent -Format 'N0'
                }
                else {
                    $diskUsagePercent.ToString("N0")
                }
                Write-Host (" | Disk: {0}%" -f $diskPercentStr) -ForegroundColor $diskColor -NoNewline
            }
            Write-Host ""
        }
        catch {
            Write-Host "⚠️ System status unavailable" -ForegroundColor Yellow
        }
    }

    # CPU monitoring
    <#
    .SYNOPSIS
        Shows detailed CPU information and usage.
    .DESCRIPTION
        Displays comprehensive CPU information including usage, processes, and system load.
    #>
    function Show-CPUInfo {
        Write-Host "🧠 CPU Information" -ForegroundColor Yellow
        Write-Host "=================" -ForegroundColor Yellow

        try {
            $cpu = Get-XPlatCpuInfo
            Write-Host "Processor Details:"
            Write-Host ("  Name: {0}" -f $cpu.Name)
            Write-Host ("  Manufacturer: {0}" -f $cpu.Manufacturer)
            Write-Host ("  Max Clock Speed: {0} MHz" -f $cpu.MaxClockSpeed)
            Write-Host ("  Cores: {0}" -f $cpu.NumberOfCores)
            Write-Host ("  Logical Processors: {0}" -f $cpu.NumberOfLogicalProcessors)
            Write-Host ("  Architecture: {0}" -f $cpu.Architecture)

            # Current usage
            Write-Host "`nCurrent Usage:"
            try {
                $cpuUsage = Get-XPlatCpuUsage
                $cpuPercentStr = if (Get-Command Format-LocaleNumber -ErrorAction SilentlyContinue) {
                    Format-LocaleNumber $cpuUsage -Format 'N1'
                }
                else {
                    $cpuUsage.ToString("N1")
                }
                Write-Host ("  Overall CPU Usage: {0}%" -f $cpuPercentStr)
            }
            catch {
                Write-Host "  Overall CPU Usage: Unable to retrieve (performance counter may not be available)" -ForegroundColor Yellow
            }

            # Top CPU-consuming processes
            Write-Host "`nTop CPU-Consuming Processes:"
            Get-Process | Sort-Object CPU -Descending | Select-Object -First 5 | Format-Table -Property @{
                Name       = "Process"
                Expression = { $_.ProcessName }
                Width      = 20
            }, @{
                Name       = "CPU(s)"
                Expression = { "{0:N2}" -f $_.CPU }
                Width      = 10
                Alignment  = "Right"
            }, @{
                Name       = "Memory"
                Expression = { "{0:N1} MB" -f ($_.WorkingSet64 / 1MB) }
                Width      = 12
                Alignment  = "Right"
            } -AutoSize
        }
        catch {
            Write-Host "CPU information unavailable" -ForegroundColor Red
        }
    }

    # Memory monitoring
    <#
    .SYNOPSIS
        Shows detailed memory usage information.
    .DESCRIPTION
        Displays comprehensive memory statistics including usage breakdown and top memory-consuming processes.
    #>
    function Show-MemoryInfo {
        Write-Host "💾 Memory Information" -ForegroundColor Green
        Write-Host "====================" -ForegroundColor Green

        try {
            $memory = Get-XPlatMemoryInfo
            $totalPhysical = [math]::Round($memory.TotalVisibleMemorySize / 1MB, 1)
            $freePhysical = [math]::Round($memory.FreePhysicalMemory / 1MB, 1)
            $usedPhysical = $totalPhysical - $freePhysical
            $physicalPercent = [math]::Round(($usedPhysical / $totalPhysical) * 100, 1)

            $totalPhysicalStr = if (Get-Command Format-LocaleNumber -ErrorAction SilentlyContinue) {
                Format-LocaleNumber $totalPhysical -Format 'N1'
            }
            else {
                $totalPhysical.ToString("N1")
            }
            $usedPhysicalStr = if (Get-Command Format-LocaleNumber -ErrorAction SilentlyContinue) {
                Format-LocaleNumber $usedPhysical -Format 'N1'
            }
            else {
                $usedPhysical.ToString("N1")
            }
            $freePhysicalStr = if (Get-Command Format-LocaleNumber -ErrorAction SilentlyContinue) {
                Format-LocaleNumber $freePhysical -Format 'N1'
            }
            else {
                $freePhysical.ToString("N1")
            }
            $physicalPercentStr = if (Get-Command Format-LocaleNumber -ErrorAction SilentlyContinue) {
                Format-LocaleNumber $physicalPercent -Format 'N1'
            }
            else {
                $physicalPercent.ToString("N1")
            }
            Write-Host "Physical Memory:"
            Write-Host ("  Total: {0} GB" -f $totalPhysicalStr)
            Write-Host ("  Used:  {0} GB ({1}%)" -f $usedPhysicalStr, $physicalPercentStr)
            Write-Host ("  Free:  {0} GB" -f $freePhysicalStr)

            # Virtual memory
            $totalVirtual = [math]::Round($memory.TotalVirtualMemorySize / 1MB, 1)
            $freeVirtual = [math]::Round($memory.FreeVirtualMemory / 1MB, 1)
            $usedVirtual = $totalVirtual - $freeVirtual
            $virtualPercent = [math]::Round(($usedVirtual / $totalVirtual) * 100, 1)

            $totalVirtualStr = if (Get-Command Format-LocaleNumber -ErrorAction SilentlyContinue) {
                Format-LocaleNumber $totalVirtual -Format 'N1'
            }
            else {
                $totalVirtual.ToString("N1")
            }
            $usedVirtualStr = if (Get-Command Format-LocaleNumber -ErrorAction SilentlyContinue) {
                Format-LocaleNumber $usedVirtual -Format 'N1'
            }
            else {
                $usedVirtual.ToString("N1")
            }
            $freeVirtualStr = if (Get-Command Format-LocaleNumber -ErrorAction SilentlyContinue) {
                Format-LocaleNumber $freeVirtual -Format 'N1'
            }
            else {
                $freeVirtual.ToString("N1")
            }
            $virtualPercentStr = if (Get-Command Format-LocaleNumber -ErrorAction SilentlyContinue) {
                Format-LocaleNumber $virtualPercent -Format 'N1'
            }
            else {
                $virtualPercent.ToString("N1")
            }
            Write-Host "`nVirtual Memory:"
            Write-Host ("  Total: {0} GB" -f $totalVirtualStr)
            Write-Host ("  Used:  {0} GB ({1}%)" -f $usedVirtualStr, $virtualPercentStr)
            Write-Host ("  Free:  {0} GB" -f $freeVirtualStr)

            # Top memory-consuming processes
            Write-Host "`nTop Memory-Consuming Processes:"
            Get-Process | Sort-Object WorkingSet64 -Descending | Select-Object -First 5 | Format-Table -Property @{
                Name       = "Process"
                Expression = { $_.ProcessName }
                Width      = 20
            }, @{
                Name       = "Memory"
                Expression = { "{0:N1} MB" -f ($_.WorkingSet64 / 1MB) }
                Width      = 12
                Alignment  = "Right"
            }, @{
                Name       = "CPU(s)"
                Expression = { "{0:N2}" -f $_.CPU }
                Width      = 10
                Alignment  = "Right"
            } -AutoSize
        }
        catch {
            Write-Host "Memory information unavailable" -ForegroundColor Red
        }
    }

    # Disk monitoring
    <#
    .SYNOPSIS
        Shows detailed disk usage information.
    .DESCRIPTION
        Displays disk space usage for all drives with detailed statistics.
    #>
    function Show-DiskInfo {
        Write-Host "💿 Disk Information" -ForegroundColor Magenta
        Write-Host "==================" -ForegroundColor Magenta

        try {
            $drives = Get-XPlatDiskInfo
            foreach ($drive in $drives) {
                $totalSpace = [math]::Round($drive.Size / 1GB, 2)
                $freeSpace = [math]::Round($drive.FreeSpace / 1GB, 2)
                $usedSpace = $totalSpace - $freeSpace
                $usagePercent = [math]::Round(($usedSpace / $totalSpace) * 100, 1)

                Write-Host ("Drive {0}:" -f $drive.DeviceID)
                Write-Host ("  File System: {0}" -f $drive.FileSystem)
                $totalSpaceStr = if (Get-Command Format-LocaleNumber -ErrorAction SilentlyContinue) {
                    Format-LocaleNumber $totalSpace -Format 'N2'
                }
                else {
                    $totalSpace.ToString("N2")
                }
                Write-Host ("  Total Space: {0} GB" -f $totalSpaceStr)
                $usedSpaceStr = if (Get-Command Format-LocaleNumber -ErrorAction SilentlyContinue) {
                    Format-LocaleNumber $usedSpace -Format 'N2'
                }
                else {
                    $usedSpace.ToString("N2")
                }
                $usagePercentStr = if (Get-Command Format-LocaleNumber -ErrorAction SilentlyContinue) {
                    Format-LocaleNumber $usagePercent -Format 'N1'
                }
                else {
                    $usagePercent.ToString("N1")
                }
                Write-Host ("  Used Space:  {0} GB ({1}%)" -f $usedSpaceStr, $usagePercentStr)
                $freeSpaceStr = if (Get-Command Format-LocaleNumber -ErrorAction SilentlyContinue) {
                    Format-LocaleNumber $freeSpace -Format 'N2'
                }
                else {
                    $freeSpace.ToString("N2")
                }
                Write-Host ("  Free Space:  {0} GB" -f $freeSpaceStr)

                # Status indicator
                $status = if ($usagePercent -gt 95) { "CRITICAL" } elseif ($usagePercent -gt 85) { "WARNING" } else { "OK" }
                $color = if ($usagePercent -gt 95) { "Red" } elseif ($usagePercent -gt 85) { "Yellow" } else { "Green" }
                Write-Host ("  Status: {0}" -f $status) -ForegroundColor $color
                Write-Host ""
            }
        }
        catch {
            Write-Host "Disk information unavailable" -ForegroundColor Red
        }
    }

    # Network monitoring
    <#
    .SYNOPSIS
        Shows detailed network information.
    .DESCRIPTION
        Displays network adapter status, IP addresses, and connectivity information.
    #>
    function Show-NetworkInfo {
        Write-Host "🌐 Network Information" -ForegroundColor Blue
        Write-Host "=====================" -ForegroundColor Blue

        try {
            $adapters = Get-NetAdapter
            foreach ($adapter in $adapters) {
                Write-Host ("Adapter: {0}" -f $adapter.Name)
                Write-Host ("  Status: {0}" -f $adapter.Status)
                Write-Host ("  MAC Address: {0}" -f $adapter.MacAddress)
                Write-Host ("  Speed: {0}" -f $(if ($adapter.LinkSpeed) { $adapter.LinkSpeed } else { "N/A" }))

                # IP addresses
                $ipAddresses = Get-NetIPAddress -InterfaceAlias $adapter.Name -ErrorAction SilentlyContinue
                if ($ipAddresses) {
                    Write-Host "  IP Addresses:"
                    $ipAddresses | ForEach-Object {
                        Write-Host ("    {0}: {1}" -f $_.AddressFamily, $_.IPAddress)
                    }
                }

                # DNS servers
                $dnsServers = Get-DnsClientServerAddress -InterfaceAlias $adapter.Name -ErrorAction SilentlyContinue
                if ($dnsServers -and $dnsServers.ServerAddresses) {
                    Write-Host ("  DNS Servers: {0}" -f ($dnsServers.ServerAddresses -join ", "))
                }
                Write-Host ""
            }

            # Connectivity tests
            Write-Host "Connectivity Tests:"
            $testHosts = @(
                @{ Name = "8.8.8.8"; Port = 53 },
                @{ Name = "google.com"; Port = 443 },
                @{ Name = "github.com"; Port = 443 }
            )
            foreach ($testHost in $testHosts) {
                $connected = $false
                $startTime = Get-Date
                $tcpClient = $null
                $connectAsync = $null

                try {
                    # Use direct TCP connection with timeout for faster and more reliable testing
                    $tcpClient = New-Object System.Net.Sockets.TcpClient
                    $connectAsync = $tcpClient.BeginConnect($testHost.Name, $testHost.Port, $null, $null)
                    $waitResult = $connectAsync.AsyncWaitHandle.WaitOne([TimeSpan]::FromSeconds(5), $false)

                    if ($waitResult) {
                        try {
                            $tcpClient.EndConnect($connectAsync)
                            if ($tcpClient.Connected) {
                                $connected = $true
                                $elapsed = ((Get-Date) - $startTime).TotalMilliseconds
                                $elapsedStr = if (Get-Command Format-LocaleNumber -ErrorAction SilentlyContinue) {
                                    Format-LocaleNumber $elapsed -Format 'N0'
                                }
                                else {
                                    $elapsed.ToString("N0")
                                }
                                Write-Host ("  {0}: ✓ (TCP port {1}, {2}ms)" -f $testHost.Name, $testHost.Port, $elapsedStr) -ForegroundColor Green
                            }
                        }
                        catch {
                            $connected = $false
                        }
                    }
                    else {
                        # Timeout
                        $connected = $false
                    }
                }
                catch {
                    $connected = $false
                }
                finally {
                    # Clean up TCP connection
                    if ($null -ne $tcpClient) {
                        if ($tcpClient.Connected) {
                            $tcpClient.Close()
                        }
                        $tcpClient.Dispose()
                    }
                    if ($null -ne $connectAsync) {
                        $connectAsync.AsyncWaitHandle.Close()
                    }
                }

                # Fallback to ping for IP addresses if TCP fails
                if (-not $connected -and $testHost.Name -match '^\d+\.\d+\.\d+\.\d+$') {
                    try {
                        $ping = Test-Connection -ComputerName $testHost.Name -Count 1 -TimeoutSeconds 3 -ErrorAction Stop
                        Write-Host ("  {0}: ✓ (ping {1}ms)" -f $testHost.Name, $ping.ResponseTime) -ForegroundColor Green
                        $connected = $true
                    }
                    catch {
                        # Ignore ping failures for IP addresses, already tried TCP
                    }
                }

                if (-not $connected) {
                    Write-Host ("  {0}: ✗ (unreachable)" -f $testHost.Name) -ForegroundColor Red
                }
            }
        }
        catch {
            Write-Host "Network information unavailable" -ForegroundColor Red
        }
    }

    # Quick aliases
    Set-AgentModeAlias -Name 'sysinfo' -Target 'Show-SystemDashboard'
    Set-AgentModeAlias -Name 'sysstat' -Target 'Show-SystemStatus'
    Set-AgentModeAlias -Name 'cpuinfo' -Target 'Show-CPUInfo'
    Set-AgentModeAlias -Name 'meminfo' -Target 'Show-MemoryInfo'
    Set-AgentModeAlias -Name 'diskinfo' -Target 'Show-DiskInfo'
    Set-AgentModeAlias -Name 'netinfo' -Target 'Show-NetworkInfo'
    Set-Variable -Name 'SystemMonitorLoaded' -Value $true -Scope Global -Force
}
catch {
    $debugLevel = Get-ProfileDebugLevel
    if ($debugLevel -ge 1) {
        if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
            Write-StructuredError -ErrorRecord $_ -OperationName 'diagnostics.system-monitor' -Context @{
                fragment = 'diagnostics-system-monitor'
            }
        }
        else {
            Write-Error "System monitor fragment failed: $($_.Exception.Message)"
        }
    }
    if ($debugLevel -ge 2) {
        Write-Verbose "[diagnostics.system-monitor] Fragment load error: $($_.Exception.Message)"
    }
    if ($debugLevel -ge 3) {
        Write-Host "  [diagnostics.system-monitor] Fragment error details - Exception: $($_.Exception.GetType().FullName), Message: $($_.Exception.Message)" -ForegroundColor DarkGray
    }
    else {
        # Always log errors even if debug is off
        if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
            Write-StructuredError -ErrorRecord $_ -OperationName 'diagnostics.system-monitor' -Context @{
                fragment = 'diagnostics-system-monitor'
            }
        }
        else {
            Write-Error "System monitor fragment failed: $($_.Exception.Message)"
        }
    }
}

