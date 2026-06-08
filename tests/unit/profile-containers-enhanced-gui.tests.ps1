# ===============================================
# profile-containers-enhanced-gui.tests.ps1
# Unit tests for Start-PodmanDesktop and Start-RancherDesktop functions
# ===============================================

BeforeAll {
    . (Join-Path $PSScriptRoot '..\TestSupport.ps1')
    $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
    . (Join-Path $script:ProfileDir 'bootstrap.ps1')
    . (Join-Path $script:ProfileDir 'containers-enhanced.ps1')
}

Describe 'containers-enhanced.ps1 - Start-PodmanDesktop' {
    BeforeEach {
        Clear-TestStartProcessCapture
        Reset-TestStartProcessMock

        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }

        Set-TestCommandAvailabilityState -CommandName 'podman-desktop' -Available $false
        Remove-Item -Path 'Function:\podman-desktop' -Force -ErrorAction SilentlyContinue
        Remove-Item -Path 'Function:\global:podman-desktop' -Force -ErrorAction SilentlyContinue
    }

    Context 'Tool not available' {
        It 'Returns null when podman-desktop is not available' {
            $result = Start-PodmanDesktop -ErrorAction SilentlyContinue

            $result | Should -BeNullOrEmpty
        }
    }

    Context 'Tool available' {
        It 'Launches podman-desktop' {
            Set-TestCommandAvailabilityState -CommandName 'podman-desktop'

            Start-PodmanDesktop -ErrorAction SilentlyContinue

            $capture = Get-TestStartProcessCapture
            $capture | Should -Not -BeNullOrEmpty
            $capture.FilePath | Should -Be 'podman-desktop'
        }

        It 'Handles Start-Process errors' {
            Set-TestCommandAvailabilityState -CommandName 'podman-desktop'
            Set-TestStartProcessFailure -Message 'Access denied'

            Start-PodmanDesktop -ErrorAction SilentlyContinue | Out-Null

            Get-TestStartProcessCapture | Should -BeNullOrEmpty
        }
    }
}

Describe 'containers-enhanced.ps1 - Start-RancherDesktop' {
    BeforeEach {
        Clear-TestStartProcessCapture
        Reset-TestStartProcessMock

        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }

        Set-TestCommandAvailabilityState -CommandName 'rancher-desktop' -Available $false
        Remove-Item -Path 'Function:\rancher-desktop' -Force -ErrorAction SilentlyContinue
        Remove-Item -Path 'Function:\global:rancher-desktop' -Force -ErrorAction SilentlyContinue
    }

    Context 'Tool not available' {
        It 'Returns null when rancher-desktop is not available' {
            $result = Start-RancherDesktop -ErrorAction SilentlyContinue

            $result | Should -BeNullOrEmpty
        }
    }

    Context 'Tool available' {
        It 'Launches rancher-desktop' {
            Set-TestCommandAvailabilityState -CommandName 'rancher-desktop'

            Start-RancherDesktop -ErrorAction SilentlyContinue

            $capture = Get-TestStartProcessCapture
            $capture | Should -Not -BeNullOrEmpty
            $capture.FilePath | Should -Be 'rancher-desktop'
        }

        It 'Handles Start-Process errors' {
            Set-TestCommandAvailabilityState -CommandName 'rancher-desktop'
            Set-TestStartProcessFailure -Message 'Access denied'

            Start-RancherDesktop -ErrorAction SilentlyContinue | Out-Null

            Get-TestStartProcessCapture | Should -BeNullOrEmpty
        }
    }
}
