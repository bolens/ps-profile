# ===============================================
# profile-database-clients-hasura.tests.ps1
# Unit tests for Invoke-Hasura function
# ===============================================

BeforeAll {
    . (Join-Path $PSScriptRoot '..\TestSupport.ps1')
    $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
    . (Join-Path $script:ProfileDir 'bootstrap.ps1')
    . (Join-Path $script:ProfileDir 'database-clients.ps1')
}

Describe 'database-clients.ps1 - Invoke-Hasura' {
    BeforeEach {
        Clear-TestCommandInvocationCapture

        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }

        Set-TestCommandAvailabilityState -CommandName 'hasura-cli' -Available $false
        Remove-Item -Path Function:\hasura-cli -Force -ErrorAction SilentlyContinue
        Remove-Item -Path Function:\global:hasura-cli -Force -ErrorAction SilentlyContinue
        Remove-Item -Path Alias:\hasura -Force -ErrorAction SilentlyContinue
        Remove-Item -Path Alias:\global:hasura -Force -ErrorAction SilentlyContinue
    }

    Context 'Tool not available' {
        It 'Returns null when hasura-cli is not available' {
            Set-TestCommandAvailabilityState -CommandName 'hasura-cli' -Available $false

            $result = Invoke-Hasura version -ErrorAction SilentlyContinue

            $result | Should -BeNullOrEmpty
        }
    }

    Context 'Tool available' {
        It 'Calls hasura-cli with correct arguments' {
            Setup-CapturingCommandMock -CommandName 'hasura-cli' -Output 'Hasura CLI version 2.0.0'

            $result = Invoke-Hasura version

            $result | Should -Not -BeNullOrEmpty
            $args = Get-TestCommandInvocationArgs
            $args | Should -Contain 'version'
        }

        It 'Handles multiple arguments' {
            Setup-CapturingCommandMock -CommandName 'hasura-cli' -Output 'Migration applied'

            $result = Invoke-Hasura migrate apply

            $result | Should -Not -BeNullOrEmpty
            $args = Get-TestCommandInvocationArgs
            $args | Should -Contain 'migrate'
            $args | Should -Contain 'apply'
        }

        It 'Handles command execution errors' {
            Set-TestCommandThrowingMock -CommandName 'hasura-cli' -Message 'hasura-cli failed'

            { Invoke-Hasura version } | Should -Throw '*hasura-cli*'
        }
    }
}
