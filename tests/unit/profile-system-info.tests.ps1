#
# Tests for system information helpers.
#

. (Join-Path $PSScriptRoot '..\TestSupport.ps1')

BeforeAll {
    $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
    . (Join-Path $script:ProfileDir '00-bootstrap.ps1')
    . (Join-Path $script:ProfileDir '08-system-info.ps1')
}

Describe 'Profile system info functions' {
    Context 'General behavior' {
        It 'uptime returns a TimeSpan object' {
            $result = uptime
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
            $result = cpuinfo
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
