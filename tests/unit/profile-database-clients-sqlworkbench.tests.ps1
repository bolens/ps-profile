# ===============================================
# profile-database-clients-sqlworkbench.tests.ps1
# Unit tests for Start-SqlWorkbench function
# ===============================================

BeforeAll {
    . (Join-Path $PSScriptRoot '..\TestSupport.ps1')
    $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
    . (Join-Path $script:ProfileDir 'bootstrap.ps1')
    . (Join-Path $script:ProfileDir 'database-clients.ps1')

    $script:TestWorkspace = Join-Path (New-TestTempDirectory -Prefix 'SqlWorkbenchWorkspace') 'workspace.xml'
    Set-Content -Path $script:TestWorkspace -Value '<?xml version="1.0"?><workspace></workspace>'
}

Describe 'database-clients.ps1 - Start-SqlWorkbench' {
    BeforeEach {
        Clear-TestStartProcessCapture

        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }

        Set-TestCommandAvailabilityState -CommandName 'sql-workbench' -Available $false
        Remove-Item -Path Function:\sql-workbench -Force -ErrorAction SilentlyContinue
        Remove-Item -Path Function:\global:sql-workbench -Force -ErrorAction SilentlyContinue

        Reset-TestStartProcessMock
    }

    Context 'Tool not available' {
        It 'Returns null when sql-workbench is not available' {
            Set-TestCommandAvailabilityState -CommandName 'sql-workbench' -Available $false

            $result = Start-SqlWorkbench -ErrorAction SilentlyContinue

            $result | Should -BeNullOrEmpty
        }
    }

    Context 'Tool available' {
        It 'Starts sql-workbench without workspace' {
            Set-TestCommandAvailabilityState -CommandName 'sql-workbench'

            $result = Start-SqlWorkbench

            $result | Should -Not -BeNullOrEmpty
            $capture = Get-TestStartProcessCapture
            $capture.FilePath | Should -Be 'sql-workbench'
        }

        It 'Starts sql-workbench with workspace file' {
            Set-TestCommandAvailabilityState -CommandName 'sql-workbench'

            $result = Start-SqlWorkbench -Workspace $script:TestWorkspace

            $result | Should -Not -BeNullOrEmpty
            $capture = Get-TestStartProcessCapture
            $capture.ArgumentList | Should -Contain $script:TestWorkspace
        }

        It 'Returns error when workspace file does not exist' {
            Set-TestCommandAvailabilityState -CommandName 'sql-workbench'
            $missingWorkspace = Join-Path (New-TestTempDirectory -Prefix 'SqlWorkbenchMissing') 'workspace.xml'

            { Start-SqlWorkbench -Workspace $missingWorkspace -ErrorAction Stop } | Should -Throw '*Workspace file not found*'
        }

        It 'Handles process start errors' {
            Set-TestCommandAvailabilityState -CommandName 'sql-workbench'
            Set-TestStartProcessFailure -Message 'Access denied'

            { Start-SqlWorkbench -ErrorAction Stop } | Should -Throw '*Access denied*'
        }
    }
}
