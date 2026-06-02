# ===============================================
# profile-database-clients-tableplus.tests.ps1
# Unit tests for Start-TablePlus function
# ===============================================

BeforeAll {
    . (Join-Path $PSScriptRoot '..\TestSupport.ps1')
    $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
    . (Join-Path $script:ProfileDir 'bootstrap.ps1')
    . (Join-Path $script:ProfileDir 'database-clients.ps1')
}

Describe 'database-clients.ps1 - Start-TablePlus' {
    BeforeEach {
        Clear-TestStartProcessCapture

        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }

        Set-TestCommandAvailabilityState -CommandName 'tableplus' -Available $false
        Remove-Item -Path Function:\tableplus -Force -ErrorAction SilentlyContinue
        Remove-Item -Path Function:\global:tableplus -Force -ErrorAction SilentlyContinue

        Reset-TestStartProcessMock
    }

    Context 'Tool not available' {
        It 'Returns null when tableplus is not available' {
            Set-TestCommandAvailabilityState -CommandName 'tableplus' -Available $false

            $result = Start-TablePlus -ErrorAction SilentlyContinue

            $result | Should -BeNullOrEmpty
        }
    }

    Context 'Tool available' {
        It 'Starts tableplus without connection' {
            Setup-AvailableCommandMock -CommandName 'tableplus'

            $result = Start-TablePlus

            $result | Should -Not -BeNullOrEmpty
            $capture = Get-TestStartProcessCapture
            $capture.FilePath | Should -Be 'tableplus'
        }

        It 'Starts tableplus with connection' {
            Setup-AvailableCommandMock -CommandName 'tableplus'

            $connection = 'my-connection'
            $result = Start-TablePlus -Connection $connection

            $result | Should -Not -BeNullOrEmpty
            $capture = Get-TestStartProcessCapture
            $capture.ArgumentList | Should -Contain $connection
        }

        It 'Handles process start errors' {
            Setup-AvailableCommandMock -CommandName 'tableplus'
            Set-TestStartProcessFailure -Message 'Access denied'

            { Start-TablePlus -ErrorAction Stop } | Should -Throw '*Access denied*'
        }
    }
}
