. (Join-Path $PSScriptRoot '..\TestSupport.ps1')

Describe 'System Monitor Integration Tests' {
    BeforeAll {
        $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
    }

    Context 'System monitor functions' {
        BeforeAll {
            # Load the system monitor fragment directly to ensure functions are available
            $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
            $systemMonitorFragment = Join-Path $script:ProfileDir '75-system-monitor.ps1'
            # Clear the guard variable to allow loading
            Remove-Variable -Name 'SystemMonitorLoaded' -Scope Global -ErrorAction SilentlyContinue
            . $systemMonitorFragment
        }

        It 'Show-SystemDashboard function is available' {
            Get-Command Show-SystemDashboard -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'Show-SystemDashboard executes without error' {
            { Show-SystemDashboard } | Should -Not -Throw
        }

        It 'Show-SystemStatus function is available' {
            Get-Command Show-SystemStatus -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'Show-SystemStatus executes without error' {
            { Show-SystemStatus } | Should -Not -Throw
        }

        It 'Show-CPUInfo function is available' {
            Get-Command Show-CPUInfo -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'Show-CPUInfo executes without error' {
            { Show-CPUInfo } | Should -Not -Throw
        }

        It 'Show-MemoryInfo function is available' {
            Get-Command Show-MemoryInfo -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'Show-MemoryInfo executes without error' {
            { Show-MemoryInfo } | Should -Not -Throw
        }

        It 'Show-DiskInfo function is available' {
            Get-Command Show-DiskInfo -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'Show-DiskInfo executes without error' {
            { Show-DiskInfo } | Should -Not -Throw
        }

        It 'Show-NetworkInfo function is available' {
            Get-Command Show-NetworkInfo -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'Show-NetworkInfo executes without error' {
            { Show-NetworkInfo } | Should -Not -Throw
        }
    }
}
