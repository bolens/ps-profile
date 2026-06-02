# ===============================================
# profile-database-clients-dbeaver.tests.ps1
# Unit tests for Start-DBeaver function
# ===============================================

BeforeAll {
    . (Join-Path $PSScriptRoot '..\TestSupport.ps1')
    $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
    . (Join-Path $script:ProfileDir 'bootstrap.ps1')
    . (Join-Path $script:ProfileDir 'database-clients.ps1')

    $script:TestWorkspace = New-TestTempDirectory -Prefix 'DBeaverWorkspace'
}

Describe 'database-clients.ps1 - Start-DBeaver' {
    BeforeEach {
        Clear-TestStartProcessCapture

        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }

        Set-TestCommandAvailabilityState -CommandName 'dbeaver' -Available $false
        Remove-Item -Path Function:\dbeaver -Force -ErrorAction SilentlyContinue
        Remove-Item -Path Function:\global:dbeaver -Force -ErrorAction SilentlyContinue

        Reset-TestStartProcessMock
    }

    Context 'Tool not available' {
        It 'Returns null when dbeaver is not available' {
            Set-TestCommandAvailabilityState -CommandName 'dbeaver' -Available $false

            $result = Start-DBeaver -ErrorAction SilentlyContinue

            $result | Should -BeNullOrEmpty
        }
    }

    Context 'Tool available' {
        It 'Starts dbeaver without workspace' {
            Setup-AvailableCommandMock -CommandName 'dbeaver'

            $result = Start-DBeaver

            $result | Should -Not -BeNullOrEmpty
            $capture = Get-TestStartProcessCapture
            $capture.FilePath | Should -Be 'dbeaver'
        }

        It 'Starts dbeaver with workspace directory' {
            Setup-AvailableCommandMock -CommandName 'dbeaver'

            $result = Start-DBeaver -Workspace $script:TestWorkspace

            $result | Should -Not -BeNullOrEmpty
            $capture = Get-TestStartProcessCapture
            $capture.ArgumentList | Should -Contain '-data'
            $capture.ArgumentList | Should -Contain $script:TestWorkspace
        }

        It 'Returns error when workspace directory does not exist' {
            Setup-AvailableCommandMock -CommandName 'dbeaver'
            $missingWorkspace = Join-Path (New-TestTempDirectory -Prefix 'DBeaverMissingParent') 'nonexistent-workspace'

            { Start-DBeaver -Workspace $missingWorkspace -ErrorAction Stop } | Should -Throw '*Workspace directory not found*'
        }

        It 'Handles process start errors' {
            Setup-AvailableCommandMock -CommandName 'dbeaver'
            Set-TestStartProcessFailure -Message 'Access denied'

            { Start-DBeaver -ErrorAction Stop } | Should -Throw '*Access denied*'
        }
    }
}
