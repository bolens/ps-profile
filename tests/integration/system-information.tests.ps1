. (Join-Path $PSScriptRoot '..\TestSupport.ps1')

Describe 'System Information Integration Tests' {
    BeforeAll {
        $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
    }

    Context 'System information functions' {
        BeforeAll {
            . (Join-Path $script:ProfileDir '00-bootstrap.ps1')
            . (Join-Path $script:ProfileDir '08-system-info.ps1')
        }

        It 'Get-SystemUptime (uptime) function is available' {
            Get-Command uptime -CommandType Alias -ErrorAction SilentlyContinue | Should -Not -Be $null
            Get-Command Get-SystemUptime -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'Get-SystemUptime returns TimeSpan object' {
            $result = Get-SystemUptime
            $result | Should -Not -BeNullOrEmpty
            $result.GetType().Name | Should -Be 'TimeSpan'
        }

        It 'Get-BatteryInfo (battery) function is available' {
            Get-Command battery -CommandType Alias -ErrorAction SilentlyContinue | Should -Not -Be $null
            Get-Command Get-BatteryInfo -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'Get-BatteryInfo returns battery information' {
            # This test may not work on systems without batteries (desktops)
            $result = Get-BatteryInfo
            # Just verify the function doesn't throw, result may be null on desktops
            { Get-BatteryInfo } | Should -Not -Throw
        }

        It 'Get-SystemInfo (sysinfo) function is available' {
            Get-Command sysinfo -CommandType Alias -ErrorAction SilentlyContinue | Should -Not -Be $null
            Get-Command Get-SystemInfo -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'Get-SystemInfo returns system information' {
            $result = Get-SystemInfo
            $result | Should -Not -BeNullOrEmpty
            $result.Name | Should -Not -BeNullOrEmpty
            $result.Manufacturer | Should -Not -BeNullOrEmpty
        }

        It 'Get-CpuInfo (cpuinfo) function is available' {
            Get-Command cpuinfo -CommandType Alias -ErrorAction SilentlyContinue | Should -Not -Be $null
            Get-Command Get-CpuInfo -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'Get-CpuInfo returns CPU information' {
            $result = Get-CpuInfo
            $result | Should -Not -BeNullOrEmpty
            $result.Name | Should -Not -BeNullOrEmpty
            $result.NumberOfCores | Should -BeGreaterThan 0
            $result.NumberOfLogicalProcessors | Should -BeGreaterThan 0
        }

        It 'Get-MemoryInfo (meminfo) function is available' {
            Get-Command meminfo -CommandType Alias -ErrorAction SilentlyContinue | Should -Not -Be $null
            Get-Command Get-MemoryInfo -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'Get-MemoryInfo returns memory information' {
            $result = Get-MemoryInfo
            $result | Should -Not -BeNullOrEmpty
            $result.'TotalMemory(GB)' | Should -BeGreaterThan 0
        }
    }
}
