# ===============================================
# profile-api-tools-httptoolkit.tests.ps1
# Unit tests for Start-HttpToolkit function
# ===============================================

BeforeAll {
    . (Join-Path $PSScriptRoot '..\TestSupport.ps1')
    $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
    . (Join-Path $script:ProfileDir 'bootstrap.ps1')
    . (Join-Path $script:ProfileDir 'api-tools.ps1')
}

Describe 'api-tools.ps1 - Start-HttpToolkit' {
    BeforeEach {
        Clear-TestStartProcessCapture

        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }

        Set-TestCommandAvailabilityState -CommandName 'httptoolkit' -Available $false
        Remove-Item -Path Function:\httptoolkit -Force -ErrorAction SilentlyContinue
        Remove-Item -Path Function:\global:httptoolkit -Force -ErrorAction SilentlyContinue

        Reset-TestStartProcessMock
    }

    Context 'Tool not available' {
        It 'Returns null when httptoolkit is not available' {
            Set-TestCommandAvailabilityState -CommandName 'httptoolkit' -Available $false

            $result = Start-HttpToolkit -ErrorAction SilentlyContinue

            $result | Should -BeNullOrEmpty
        }
    }

    Context 'Tool available' {
        It 'Starts httptoolkit with default port' {
            Setup-AvailableCommandMock -CommandName 'httptoolkit'

            $result = Start-HttpToolkit

            $result | Should -Not -BeNullOrEmpty
            $capture = Get-TestStartProcessCapture
            $capture.FilePath | Should -Be 'httptoolkit'
            $capture.ArgumentList | Should -Contain '--port'
            $capture.ArgumentList | Should -Contain '8000'
        }

        It 'Starts httptoolkit with specified port' {
            Setup-AvailableCommandMock -CommandName 'httptoolkit'

            $result = Start-HttpToolkit -Port 9000

            $result | Should -Not -BeNullOrEmpty
            $capture = Get-TestStartProcessCapture
            $capture.ArgumentList | Should -Contain '--port'
            $capture.ArgumentList | Should -Contain '9000'
        }

        It 'Includes passthrough parameter when specified' {
            Setup-AvailableCommandMock -CommandName 'httptoolkit'

            $result = Start-HttpToolkit -Passthrough

            $result | Should -Not -BeNullOrEmpty
            $capture = Get-TestStartProcessCapture
            $capture.ArgumentList | Should -Contain '--passthrough'
        }

        It 'Uses PassThru and NoNewWindow parameters for Start-Process' {
            Setup-AvailableCommandMock -CommandName 'httptoolkit'

            $result = Start-HttpToolkit

            $result | Should -Not -BeNullOrEmpty
            $capture = Get-TestStartProcessCapture
            $capture.PassThru | Should -Be $true
            $capture.NoNewWindow | Should -Be $true
        }

        It 'Handles Start-Process errors' {
            Setup-AvailableCommandMock -CommandName 'httptoolkit'
            Set-TestStartProcessFailure -Message 'Failed to start process'

            { Start-HttpToolkit -ErrorAction Stop } | Should -Throw '*Failed to start process*'
        }
    }
}
