# ===============================================
# profile-iac-tools-terragrunt.tests.ps1
# Unit tests for Remove-TerraformInfrastructure function
# ===============================================

BeforeAll {
    . (Join-Path $PSScriptRoot '..\TestSupport.ps1')
    $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
    . (Join-Path $script:ProfileDir 'bootstrap.ps1')
    . (Join-Path $script:ProfileDir 'terraform.ps1')
}

Describe 'terraform.ps1 - Remove-TerraformInfrastructure' {
    BeforeEach {
        Clear-TestCommandInvocationCapture

        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }

        Set-TestCommandAvailabilityState -CommandName 'terraform' -Available $false
        Remove-Item -Path 'Function:\terraform' -Force -ErrorAction SilentlyContinue
        Remove-Item -Path 'Function:\global:terraform' -Force -ErrorAction SilentlyContinue
    }

    Context 'Tool not available' {
        It 'Returns null when terraform is not available' {
            $result = Remove-TerraformInfrastructure -ErrorAction SilentlyContinue

            $result | Should -BeNullOrEmpty
        }
    }

    Context 'terraform available' {
        It 'Calls terraform destroy with default settings' {
            Setup-CapturingCommandMock -CommandName 'terraform' -Output 'Destroy output'

            $result = Remove-TerraformInfrastructure -ErrorAction SilentlyContinue

            $args = Get-TestCommandInvocationArgsFlat
            $args | Should -Contain 'destroy'
            $result | Should -Be 'Destroy output'
            $global:TestCommandInvocationCaptures.Count | Should -Be 1
        }

        It 'Calls terraform destroy with auto-approve' {
            Setup-CapturingCommandMock -CommandName 'terraform' -Output 'Destroy output'

            Remove-TerraformInfrastructure '-auto-approve' -ErrorAction SilentlyContinue | Out-Null

            $args = Get-TestCommandInvocationArgsFlat
            $args | Should -Contain '-auto-approve'
        }

        It 'Handles terraform destroy execution errors' {
            Set-TestCommandThrowingMock -CommandName 'terraform' -Message 'Command not found'

            { Remove-TerraformInfrastructure -ErrorAction Stop } | Should -Throw
        }
    }
}
