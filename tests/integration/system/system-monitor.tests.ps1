

Describe 'System Monitor Integration Tests' {
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
            Write-Error "Failed to initialize system monitor tests in BeforeAll: $($errorDetails | ConvertTo-Json -Compress)" -ErrorAction Stop
            throw
        }
    }

    Context 'System monitor functions' {
        BeforeAll {
            # Load the system monitor fragment directly to ensure functions are available
            $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
            $systemMonitorFragment = Join-Path $script:ProfileDir 'system-monitor.ps1'
            # Clear the guard variable to allow loading
            Remove-Variable -Name 'SystemMonitorLoaded' -Scope Global -ErrorAction SilentlyContinue
            . $systemMonitorFragment
        }

        It 'Show-SystemDashboard function is available' {
            Get-Command Show-SystemDashboard -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'Show-SystemDashboard executes without error' {
            try {
                { Show-SystemDashboard } | Should -Not -Throw -Because "Show-SystemDashboard should execute without errors"
            }
            catch {
                $errorDetails = @{
                    Message  = $_.Exception.Message
                    Function = 'Show-SystemDashboard'
                    Category = $_.CategoryInfo.Category
                }
                Write-Error "Show-SystemDashboard execution test failed: $($errorDetails | ConvertTo-Json -Compress)" -ErrorAction Continue
                throw
            }
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

