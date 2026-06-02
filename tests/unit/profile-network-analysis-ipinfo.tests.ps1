# ===============================================
# profile-network-analysis-ipinfo.tests.ps1
# Unit tests for Get-IpInfo function
# ===============================================

BeforeAll {
    . (Join-Path $PSScriptRoot '..\TestSupport.ps1')
    $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
    . (Join-Path $script:ProfileDir 'bootstrap.ps1')
    . (Join-Path $script:ProfileDir 'network-analysis.ps1')
}

Describe 'network-analysis.ps1 - Get-IpInfo' {
    BeforeEach {
        Clear-TestCommandInvocationCapture

        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }

        Set-TestCommandAvailabilityState -CommandName 'nali' -Available $false
        Set-TestCommandAvailabilityState -CommandName 'ipinfo' -Available $false
        Remove-Item -Path 'Function:\nali' -Force -ErrorAction SilentlyContinue
        Remove-Item -Path 'Function:\global:nali' -Force -ErrorAction SilentlyContinue
        Remove-Item -Path 'Function:\ipinfo' -Force -ErrorAction SilentlyContinue
        Remove-Item -Path 'Function:\global:ipinfo' -Force -ErrorAction SilentlyContinue
    }

    Context 'Tool not available' {
        It 'Returns null when nali is not available' {
            $result = Get-IpInfo -IpAddress '8.8.8.8' -Tool 'nali' -ErrorAction SilentlyContinue

            $result | Should -BeNullOrEmpty
        }

        It 'Returns null when ipinfo is not available' {
            $result = Get-IpInfo -IpAddress '8.8.8.8' -Tool 'ipinfo' -ErrorAction SilentlyContinue

            $result | Should -BeNullOrEmpty
        }
    }

    Context 'Nali tool' {
        It 'Calls nali with IP address' {
            Setup-CapturingCommandMock -CommandName 'nali' -Output '8.8.8.8 [US]'

            $result = Get-IpInfo -IpAddress '8.8.8.8' -Tool 'nali' -ErrorAction SilentlyContinue

            $args = Get-TestCommandInvocationArgsFlat
            $args | Should -Contain '8.8.8.8'
            $result | Should -Be '8.8.8.8 [US]'
        }

        It 'Handles nali execution errors' {
            Setup-CapturingCommandMock -CommandName 'nali' -ExitCode 1

            $result = Get-IpInfo -IpAddress '8.8.8.8' -Tool 'nali' -ErrorAction SilentlyContinue

            $result | Should -BeNullOrEmpty
        }
    }

    Context 'Ipinfo tool' {
        It 'Calls ipinfo with IP address' {
            Setup-CapturingCommandMock -CommandName 'ipinfo' -Output 'IP: 8.8.8.8'

            $result = Get-IpInfo -IpAddress '8.8.8.8' -Tool 'ipinfo' -ErrorAction SilentlyContinue

            $args = Get-TestCommandInvocationArgsFlat
            $args | Should -Contain '8.8.8.8'
            $result | Should -Be 'IP: 8.8.8.8'
        }

        It 'Calls ipinfo with JSON format' {
            Setup-CapturingCommandMock -CommandName 'ipinfo' -Output '{"ip": "8.8.8.8"}'

            Get-IpInfo -IpAddress '8.8.8.8' -Tool 'ipinfo' -OutputFormat 'json' -ErrorAction SilentlyContinue | Out-Null

            $args = Get-TestCommandInvocationArgsFlat
            $args | Should -Contain '--json'
        }

        It 'Handles ipinfo execution errors' {
            Setup-CapturingCommandMock -CommandName 'ipinfo' -ExitCode 1

            { Get-IpInfo -IpAddress '8.8.8.8' -Tool 'ipinfo' -ErrorAction Stop } | Should -Throw
        }
    }
}
