# ===============================================
# profile-mobile-dev-ios.tests.ps1
# Unit tests for iOS functions
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
    . (Join-Path $script:ProfileDir 'mobile-dev.ps1')
}

Describe 'mobile-dev.ps1 - iOS Functions' {
    BeforeEach {
        Clear-TestCommandInvocationCapture

        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }

        Set-TestCommandAvailabilityState -CommandName 'idevice_id' -Available $false
        Remove-Item -Path 'Function:\idevice_id' -Force -ErrorAction SilentlyContinue
        Remove-Item -Path 'Function:\global:idevice_id' -Force -ErrorAction SilentlyContinue
    }

    Context 'Connect-IOSDevice' {
        It 'Returns empty array when idevice_id is not available' {
            $result = Connect-IOSDevice -ErrorAction SilentlyContinue

            $result | Should -BeNullOrEmpty
        }

        It 'Lists devices when ListDevices is specified' {
            Setup-CapturingCommandMock -CommandName 'idevice_id' -OnInvoke {
                return @(
                    'a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0',
                    'f0e9d8c7b6a5f4e3d2c1b0a9f8e7d6c5b4a3c2d1'
                )
            }

            $result = Connect-IOSDevice -ListDevices -ErrorAction SilentlyContinue

            $result | Should -Not -BeNullOrEmpty
            @($result).Count | Should -BeGreaterThan 0
        }

        It 'Verifies specific device ID when provided' {
            Setup-CapturingCommandMock -CommandName 'idevice_id' -OnInvoke {
                return @(
                    'a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0',
                    'f0e9d8c7b6a5f4e3d2c1b0a9f8e7d6c5b4a3c2d1'
                )
            }

            $result = Connect-IOSDevice -DeviceId 'a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0' -ErrorAction SilentlyContinue

            $result | Should -Not -BeNullOrEmpty
            $result | Should -Contain 'a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0'
        }

        It 'Warns when device ID not found' {
            Setup-CapturingCommandMock -CommandName 'idevice_id' -OnInvoke {
                return @('a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0')
            }

            $result = Connect-IOSDevice -DeviceId 'nonexistent-device-id' -ErrorAction SilentlyContinue

            $result | Should -BeNullOrEmpty
        }
    }
}
