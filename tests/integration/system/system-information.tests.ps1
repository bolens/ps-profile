

Describe 'System Information Integration Tests' {
    BeforeAll {
        try {
            $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
            if ($null -eq $script:ProfileDir -or [string]::IsNullOrWhiteSpace($script:ProfileDir)) {
                throw "Get-TestPath returned null or empty value for ProfileDir"
            }
            if (-not (Test-Path -LiteralPath $script:ProfileDir)) {
                throw "Profile directory not found at: $script:ProfileDir"
            }
        }
        catch {
            $errorDetails = @{
                Message  = $_.Exception.Message
                Type     = $_.Exception.GetType().FullName
                Location = $_.InvocationInfo.ScriptLineNumber
            }
            Write-Error "Failed to initialize system information tests in BeforeAll: $($errorDetails | ConvertTo-Json -Compress)" -ErrorAction Stop
            throw
        }
    }

    Context 'System information functions' {
        BeforeAll {
            . (Join-Path $script:ProfileDir 'bootstrap.ps1')
            . (Join-Path $script:ProfileDir 'system-info.ps1')
        }

        It 'Get-SystemUptime (uptime) function is available' {
            Get-Command uptime -CommandType Alias -ErrorAction SilentlyContinue | Should -Not -Be $null
            Get-Command Get-SystemUptime -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'Get-SystemUptime returns TimeSpan object' {
            try {
                $result = Get-SystemUptime
                $result | Should -Not -BeNullOrEmpty -Because "Get-SystemUptime should return a result"
                $result.GetType().Name | Should -Be 'TimeSpan' -Because "Get-SystemUptime should return a TimeSpan object"
            }
            catch {
                $errorDetails = @{
                    Message  = $_.Exception.Message
                    Function = 'Get-SystemUptime'
                    Category = $_.CategoryInfo.Category
                }
                Write-Error "Get-SystemUptime test failed: $($errorDetails | ConvertTo-Json -Compress)" -ErrorAction Continue
                throw
            }
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

