# ===============================================
# profile-network-analysis-scan.tests.ps1
# Unit tests for Invoke-NetworkScan function
# ===============================================

BeforeAll {
    $current = Get-Item $PSScriptRoot
    while ($null -ne $current) {
        $testSupportPath = Join-Path $current.FullName 'TestSupport.ps1'
        if (Test-Path -LiteralPath $testSupportPath) {
            . $testSupportPath
            break
        }
        if ($current.Name -eq 'tests' -or $current.Parent -eq $null) { break }
        $current = $current.Parent
    }
    $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
    . (Join-Path $script:ProfileDir 'bootstrap.ps1')
    . (Join-Path $script:ProfileDir 'network-analysis.ps1')
}

Describe 'network-analysis.ps1 - Invoke-NetworkScan' {
    BeforeEach {
        Clear-TestCommandInvocationCapture
        Clear-TestStartProcessCapture
        Reset-TestStartProcessMock

        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }

        Set-TestCommandAvailabilityState -CommandName 'sniffnet' -Available $false
        Set-TestCommandAvailabilityState -CommandName 'trippy' -Available $false
        Remove-Item -Path 'Function:\sniffnet' -Force -ErrorAction SilentlyContinue
        Remove-Item -Path 'Function:\global:sniffnet' -Force -ErrorAction SilentlyContinue
        Remove-Item -Path 'Function:\trippy' -Force -ErrorAction SilentlyContinue
        Remove-Item -Path 'Function:\global:trippy' -Force -ErrorAction SilentlyContinue
    }

    Context 'Tool not available' {
        It 'Returns null when sniffnet is not available' {
            $result = Invoke-NetworkScan -Target '192.168.1.0/24' -Tool 'sniffnet' -ErrorAction SilentlyContinue

            $result | Should -BeNullOrEmpty
        }

        It 'Returns null when trippy is not available' {
            $result = Invoke-NetworkScan -Target '192.168.1.1' -Tool 'trippy' -ErrorAction SilentlyContinue

            $result | Should -BeNullOrEmpty
        }
    }

    Context 'Sniffnet tool' {
        It 'Launches sniffnet' {
            Set-TestCommandAvailabilityState -CommandName 'sniffnet'

            Invoke-NetworkScan -Target '192.168.1.0/24' -Tool 'sniffnet' -ErrorAction SilentlyContinue | Out-Null

            $capture = Get-TestStartProcessCapture
            $capture | Should -Not -BeNullOrEmpty
            $capture.FilePath | Should -Be 'sniffnet'
        }

        It 'Handles Start-Process errors for sniffnet' {
            Set-TestCommandAvailabilityState -CommandName 'sniffnet'
            Set-TestStartProcessFailure -Message 'Access denied'

            { Invoke-NetworkScan -Target '192.168.1.0/24' -Tool 'sniffnet' -ErrorAction Stop } | Should -Throw '*Access denied*'
        }
    }

    Context 'Trippy tool' {
        It 'Calls trippy with correct arguments' {
            Setup-CapturingCommandMock -CommandName 'trippy' -Output 'Scan results'

            $result = Invoke-NetworkScan -Target '192.168.1.1' -Tool 'trippy' -ErrorAction SilentlyContinue

            $args = Get-TestCommandInvocationArgsFlat
            $args | Should -Contain '192.168.1.1'
            $result | Should -Be 'Scan results'
        }

        It 'Calls trippy with JSON format' {
            Setup-CapturingCommandMock -CommandName 'trippy' -Output '{"results": "json"}'

            Invoke-NetworkScan -Target '192.168.1.1' -Tool 'trippy' -OutputFormat 'json' -ErrorAction SilentlyContinue | Out-Null

            $args = Get-TestCommandInvocationArgsFlat
            $args | Should -Contain '--json'
        }

        It 'Handles trippy execution errors' {
            Setup-CapturingCommandMock -CommandName 'trippy' -ExitCode 1

            { Invoke-NetworkScan -Target '192.168.1.1' -Tool 'trippy' -ErrorAction Stop } | Should -Throw
        }
    }
}
