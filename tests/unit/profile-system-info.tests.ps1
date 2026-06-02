#
# Tests for system information helpers.
#

BeforeAll {
    . (Join-Path $PSScriptRoot '..\TestSupport.ps1')
    $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
    . (Join-Path $script:ProfileDir 'bootstrap.ps1')
    . (Join-Path $script:ProfileDir 'system-info.ps1')
}

Describe 'Profile system info functions' {
    Context 'General behavior' {
        It 'uptime returns a TimeSpan object' {
            # Native `uptime` may exist on PATH and block the profile alias; test the function directly.
            $result = Get-SystemUptime
            $result | Should -Not -Be $null
            $result.GetType().Name | Should -Be 'TimeSpan'
        }

        It 'sysinfo returns computer system information' {
            $result = sysinfo
            $result | Should -Not -Be $null
            ($result | Get-Member -MemberType Properties).Name -contains 'Name' | Should -Be $true
            ($result | Get-Member -MemberType Properties).Name -contains 'Manufacturer' | Should -Be $true
        }

        It 'cpuinfo returns processor information' {
            # Python cpuinfo may exist on PATH and block the profile alias; test the function directly.
            $result = Get-CpuInfo
            $result | Should -Not -Be $null
            ($result | Get-Member -MemberType Properties).Name -contains 'Name' | Should -Be $true
            ($result | Get-Member -MemberType Properties).Name -contains 'NumberOfCores' | Should -Be $true
        }

        It 'meminfo returns memory information' {
            $result = meminfo
            $result | Should -Not -Be $null
            ($result | Get-Member -MemberType Properties).Name -contains 'TotalMemory(GB)' | Should -Be $true
            $result.'TotalMemory(GB)' | Should -BeGreaterThan 0
        }
    }
}
