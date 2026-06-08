# ===============================================
# profile-network-analysis-wireshark.tests.ps1
# Unit tests for Start-Wireshark function
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

Describe 'network-analysis.ps1 - Start-Wireshark' {
    BeforeEach {
        Clear-TestStartProcessCapture
        Reset-TestStartProcessMock

        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }

        Set-TestCommandAvailabilityState -CommandName 'wireshark' -Available $false
        Remove-Item -Path 'Function:\wireshark' -Force -ErrorAction SilentlyContinue
        Remove-Item -Path 'Function:\global:wireshark' -Force -ErrorAction SilentlyContinue
    }

    Context 'Tool not available' {
        It 'Returns null when wireshark is not available' {
            $result = Start-Wireshark -ErrorAction SilentlyContinue

            $result | Should -BeNullOrEmpty
        }
    }

    Context 'Tool available' {
        It 'Launches wireshark without arguments' {
            Set-TestCommandAvailabilityState -CommandName 'wireshark'

            Start-Wireshark -ErrorAction SilentlyContinue | Out-Null

            $capture = Get-TestStartProcessCapture
            $capture | Should -Not -BeNullOrEmpty
            $capture.FilePath | Should -Be 'wireshark'
            @($capture.ArgumentList | Where-Object { $null -ne $_ -and $_ -ne '' }).Count | Should -Be 0
        }

        It 'Launches wireshark with capture file' {
            Set-TestCommandAvailabilityState -CommandName 'wireshark'
            $testDir = New-TestTempDirectory -Prefix 'WiresharkCapture'
            $testFile = Join-Path $testDir 'capture.pcap'
            'test content' | Out-File -FilePath $testFile -Encoding utf8

            Start-Wireshark -CaptureFile $testFile -ErrorAction SilentlyContinue | Out-Null

            $capture = Get-TestStartProcessCapture
            $capture.ArgumentList | Should -Contain $testFile
        }

        It 'Launches wireshark with interface' {
            Set-TestCommandAvailabilityState -CommandName 'wireshark'

            Start-Wireshark -Interface 'Ethernet' -ErrorAction SilentlyContinue | Out-Null

            $capture = Get-TestStartProcessCapture
            $capture.ArgumentList | Should -Contain '-i'
            $capture.ArgumentList | Should -Contain 'Ethernet'
        }

        It 'Returns error when capture file does not exist' {
            Set-TestCommandAvailabilityState -CommandName 'wireshark'

            Start-Wireshark -CaptureFile 'nonexistent.pcap' -ErrorAction SilentlyContinue | Out-Null

            Get-TestStartProcessCapture | Should -BeNullOrEmpty
        }

        It 'Handles Start-Process errors' {
            Set-TestCommandAvailabilityState -CommandName 'wireshark'
            Set-TestStartProcessFailure -Message 'Access denied'

            { Start-Wireshark -ErrorAction Stop } | Should -Throw '*Access denied*'
        }
    }
}
