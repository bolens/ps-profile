# ===============================================
# System monitoring diagnostic functions
# System dashboard, CPU, memory, disk, and network monitoring
# ===============================================

<#
System monitoring dashboard for PowerShell profile.
Provides quick overview of CPU, memory, disk, and network status.
#>

try {
    if ($null -ne (Get-Variable -Name 'SystemMonitorLoaded' -Scope Global -ErrorAction SilentlyContinue)) { return }

    # System monitoring dashboard
    <#
    .SYNOPSIS
        Shows a comprehensive system status dashboard.
    .DESCRIPTION
        Displays CPU usage, memory usage, disk space, network status,
        and other system metrics in a clean, organized format.
    #>
    function Show-SystemDashboard {
        Write-Host "🖥️  System Dashboard" -ForegroundColor Cyan
        Write-Host "==================" -ForegroundColor Cyan

        # CPU Information
        Write-Host "`n🧠 CPU Information:" -ForegroundColor Yellow
        try {
            $cpu = Get-CimInstance Win32_Processor -ErrorAction Stop
            try {
                $cpuUsage = (Get-Counter '\Processor(_Total)\% Processor Time' -SampleInterval 1 -MaxSamples 1 -ErrorAction Stop).CounterSamples.CookedValue
                Write-Host ("  Usage: {0:N1}%" -f $cpuUsage)
            }
            catch {
                Write-Host "  Usage: Unable to retrieve CPU usage" -ForegroundColor Yellow
            }
            Write-Host ("  Model: {0}" -f $cpu.Name)
            Write-Host ("  Cores: {0} physical, {1} logical" -f $cpu.NumberOfCores, $cpu.NumberOfLogicalProcessors)
        }
        catch [System.Management.ManagementException] {
            Write-Host "  CPU info unavailable (WMI/CIM error)" -ForegroundColor Red
        }
        catch {
            Write-Host "  CPU info unavailable: $($_.Exception.Message)" -ForegroundColor Red
        }

        # Memory Information
        Write-Host "`n💾 Memory Information:" -ForegroundColor Green
        try {
            $memory = Get-CimInstance Win32_OperatingSystem
            $totalMemory = [math]::Round($memory.TotalVisibleMemorySize / 1MB, 1)
            $freeMemory = [math]::Round($memory.FreePhysicalMemory / 1MB, 1)
            $usedMemory = $totalMemory - $freeMemory
            $memoryUsagePercent = [math]::Round(($usedMemory / $totalMemory) * 100, 1)

            Write-Host ("  Total: {0:N1} GB" -f $totalMemory)
            Write-Host ("  Used:  {0:N1} GB ({1:N1}%)" -f $usedMemory, $memoryUsagePercent)
            Write-Host ("  Free:  {0:N1} GB" -f $freeMemory)

            # Color coding for memory usage
            $color = if ($memoryUsagePercent -gt 90) { "Red" } elseif ($memoryUsagePercent -gt 75) { "Yellow" } else { "Green" }
            Write-Host ("  Status: {0}" -f $(if ($memoryUsagePercent -gt 90) { "Critical" } elseif ($memoryUsagePercent -gt 75) { "High" } else { "Normal" })) -ForegroundColor $color
        }
        catch {
            Write-Host "  Memory info unavailable" -ForegroundColor Red
        }

        # Disk Information
        Write-Host "`n💿 Disk Information:" -ForegroundColor Magenta
        try {
            $drives = Get-CimInstance Win32_LogicalDisk | Where-Object { $_.DriveType -eq 3 } # Fixed drives only
            foreach ($drive in $drives) {
                $totalSpace = [math]::Round($drive.Size / 1GB, 1)
                $freeSpace = [math]::Round($drive.FreeSpace / 1GB, 1)
                $usedSpace = $totalSpace - $freeSpace
                $usagePercent = [math]::Round(($usedSpace / $totalSpace) * 100, 1)

                Write-Host ("  {0}: {1:N1} GB used of {2:N1} GB ({3:N1}%)" -f $drive.DeviceID, $usedSpace, $totalSpace, $usagePercent)

                # Color coding for disk usage
                $color = if ($usagePercent -gt 95) { "Red" } elseif ($usagePercent -gt 85) { "Yellow" } else { "Green" }
                Write-Host ("      Status: {0}" -f $(if ($usagePercent -gt 95) { "Critical" } elseif ($usagePercent -gt 85) { "Warning" } else { "OK" })) -ForegroundColor $color
            }
        }
        catch {
            Write-Host "  Disk info unavailable" -ForegroundColor Red
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
            Write-Host "  Network info unavailable" -ForegroundColor Red
        }

        # System Uptime
        Write-Host "`n⏰ System Uptime:" -ForegroundColor White
        try {
            $uptime = (Get-Date) - (Get-CimInstance Win32_OperatingSystem).LastBootUpTime
            Write-Host ("  {0} days, {1} hours, {2} minutes" -f $uptime.Days, $uptime.Hours, $uptime.Minutes)
        }
        catch {
            Write-Host "  Uptime info unavailable" -ForegroundColor Red
        }

        # PowerShell Session Info
        Write-Host "`n💻 PowerShell Session:" -ForegroundColor Gray
        Write-Host ("  Version: {0}" -f $PSVersionTable.PSVersion)
        Write-Host ("  Edition: {0}" -f $PSVersionTable.PSEdition)
        Write-Host ("  Profile loaded: {0}" -f $(if ($global:PSProfileStartTime) { "Yes" } else { "No" }))

        if ($global:PSProfileStartTime) {
            $profileUptime = (Get-Date) - $global:PSProfileStartTime
            Write-Host ("  Profile uptime: {0:N1} minutes" -f $profileUptime.TotalMinutes)
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
            $cpuUsage = (Get-Counter '\Processor(_Total)\% Processor Time' -SampleInterval 1 -MaxSamples 1 -ErrorAction SilentlyContinue).CounterSamples.CookedValue
            $cpuColor = if ($cpuUsage -gt 80) { "Red" } elseif ($cpuUsage -gt 60) { "Yellow" } else { "Green" }

            # Memory
            $memory = Get-CimInstance Win32_OperatingSystem -ErrorAction SilentlyContinue
            if ($memory) {
                $totalMemory = $memory.TotalVisibleMemorySize / 1MB
                $freeMemory = $memory.FreePhysicalMemory / 1MB
                $memoryUsagePercent = (($totalMemory - $freeMemory) / $totalMemory) * 100
                $memoryColor = if ($memoryUsagePercent -gt 90) { "Red" } elseif ($memoryUsagePercent -gt 75) { "Yellow" } else { "Green" }
            }

            # Disk (C: drive)
            $disk = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='C:'" -ErrorAction SilentlyContinue
            if ($disk -and $disk.Size -gt 0) {
                $diskUsagePercent = (($disk.Size - $disk.FreeSpace) / $disk.Size) * 100
                $diskColor = if ($diskUsagePercent -gt 95) { "Red" } elseif ($diskUsagePercent -gt 85) { "Yellow" } else { "Green" }
            }

            Write-Host "🖥️ System Status:" -ForegroundColor Cyan -NoNewline
            Write-Host (" CPU: {0:N0}%" -f $cpuUsage) -ForegroundColor $cpuColor -NoNewline
            if ($memory) {
                Write-Host (" | RAM: {0:N0}%" -f $memoryUsagePercent) -ForegroundColor $memoryColor -NoNewline
            }
            if ($disk) {
                Write-Host (" | Disk: {0:N0}%" -f $diskUsagePercent) -ForegroundColor $diskColor -NoNewline
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
            $cpu = Get-CimInstance Win32_Processor
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
                $cpuUsage = (Get-Counter '\Processor(_Total)\% Processor Time' -SampleInterval 1 -MaxSamples 1 -ErrorAction Stop).CounterSamples.CookedValue
                Write-Host ("  Overall CPU Usage: {0:N1}%" -f $cpuUsage)
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
            $memory = Get-CimInstance Win32_OperatingSystem
            $totalPhysical = [math]::Round($memory.TotalVisibleMemorySize / 1MB, 1)
            $freePhysical = [math]::Round($memory.FreePhysicalMemory / 1MB, 1)
            $usedPhysical = $totalPhysical - $freePhysical
            $physicalPercent = [math]::Round(($usedPhysical / $totalPhysical) * 100, 1)

            Write-Host "Physical Memory:"
            Write-Host ("  Total: {0:N1} GB" -f $totalPhysical)
            Write-Host ("  Used:  {0:N1} GB ({1:N1}%)" -f $usedPhysical, $physicalPercent)
            Write-Host ("  Free:  {0:N1} GB" -f $freePhysical)

            # Virtual memory
            $totalVirtual = [math]::Round($memory.TotalVirtualMemorySize / 1MB, 1)
            $freeVirtual = [math]::Round($memory.FreeVirtualMemory / 1MB, 1)
            $usedVirtual = $totalVirtual - $freeVirtual
            $virtualPercent = [math]::Round(($usedVirtual / $totalVirtual) * 100, 1)

            Write-Host "`nVirtual Memory:"
            Write-Host ("  Total: {0:N1} GB" -f $totalVirtual)
            Write-Host ("  Used:  {0:N1} GB ({1:N1}%)" -f $usedVirtual, $virtualPercent)
            Write-Host ("  Free:  {0:N1} GB" -f $freeVirtual)

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
            $drives = Get-CimInstance Win32_LogicalDisk | Where-Object { $_.DriveType -eq 3 }
            foreach ($drive in $drives) {
                $totalSpace = [math]::Round($drive.Size / 1GB, 2)
                $freeSpace = [math]::Round($drive.FreeSpace / 1GB, 2)
                $usedSpace = $totalSpace - $freeSpace
                $usagePercent = [math]::Round(($usedSpace / $totalSpace) * 100, 1)

                Write-Host ("Drive {0}:" -f $drive.DeviceID)
                Write-Host ("  File System: {0}" -f $drive.FileSystem)
                Write-Host ("  Total Space: {0:N2} GB" -f $totalSpace)
                Write-Host ("  Used Space:  {0:N2} GB ({1:N1}%)" -f $usedSpace, $usagePercent)
                Write-Host ("  Free Space:  {0:N2} GB" -f $freeSpace)

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
                                Write-Host ("  {0}: ✓ (TCP port {1}, {2:N0}ms)" -f $testHost.Name, $testHost.Port, $elapsed) -ForegroundColor Green
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
    Set-Alias -Name sysinfo -Value Show-SystemDashboard -ErrorAction SilentlyContinue
    Set-Alias -Name sysstat -Value Show-SystemStatus -ErrorAction SilentlyContinue
    Set-Alias -Name cpuinfo -Value Show-CPUInfo -ErrorAction SilentlyContinue
    Set-Alias -Name meminfo -Value Show-MemoryInfo -ErrorAction SilentlyContinue
    Set-Alias -Name diskinfo -Value Show-DiskInfo -ErrorAction SilentlyContinue
    Set-Alias -Name netinfo -Value Show-NetworkInfo -ErrorAction SilentlyContinue

    Set-Variable -Name 'SystemMonitorLoaded' -Value $true -Scope Global -Force
}
catch {
    if ($env:PS_PROFILE_DEBUG) { Write-Verbose "System monitor fragment failed: $($_.Exception.Message)" }
}

