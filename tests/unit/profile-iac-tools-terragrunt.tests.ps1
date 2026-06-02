# ===============================================
# profile-iac-tools-terragrunt.tests.ps1
# Unit tests for Invoke-Terragrunt and Invoke-OpenTofu functions
# ===============================================

BeforeAll {
    . (Join-Path $PSScriptRoot '..\TestSupport.ps1')
    $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
    . (Join-Path $script:ProfileDir 'bootstrap.ps1')
    . (Join-Path $script:ProfileDir 'iac-tools.ps1')
}

Describe 'iac-tools.ps1 - Invoke-Terragrunt' {
    BeforeEach {
        Clear-TestCommandInvocationCapture

        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }

        Set-TestCommandAvailabilityState -CommandName 'terragrunt' -Available $false
        Remove-Item -Path 'Function:\terragrunt' -Force -ErrorAction SilentlyContinue
        Remove-Item -Path 'Function:\global:terragrunt' -Force -ErrorAction SilentlyContinue
    }

    Context 'Tool not available' {
        It 'Returns null when terragrunt is not available' {
            $result = Invoke-Terragrunt plan -ErrorAction SilentlyContinue

            $result | Should -BeNullOrEmpty
        }
    }

    Context 'Tool available' {
        It 'Calls terragrunt with arguments' {
            Setup-CapturingCommandMock -CommandName 'terragrunt' -Output 'Plan output'

            Invoke-Terragrunt plan -ErrorAction SilentlyContinue | Out-Null

            $args = Get-TestCommandInvocationArgsFlat
            $args | Should -Contain 'plan'
            $global:TestCommandInvocationCaptures.Count | Should -Be 1
        }

        It 'Calls terragrunt with multiple arguments' {
            Setup-CapturingCommandMock -CommandName 'terragrunt' -Output 'Apply output'

            Invoke-Terragrunt apply -auto-approve -ErrorAction SilentlyContinue | Out-Null

            $args = Get-TestCommandInvocationArgsFlat
            $args | Should -Contain 'apply'
            $args | Should -Contain '-auto-approve'
        }

        It 'Handles terragrunt execution errors' {
            Set-TestCommandThrowingMock -CommandName 'terragrunt' -Message 'Command not found'

            { Invoke-Terragrunt plan -ErrorAction Stop } | Should -Throw
        }
    }
}

Describe 'iac-tools.ps1 - Invoke-OpenTofu' {
    BeforeEach {
        Clear-TestCommandInvocationCapture

        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }

        Set-TestCommandAvailabilityState -CommandName 'tofu' -Available $false
        Remove-Item -Path 'Function:\tofu' -Force -ErrorAction SilentlyContinue
        Remove-Item -Path 'Function:\global:tofu' -Force -ErrorAction SilentlyContinue
    }

    Context 'Tool not available' {
        It 'Returns null when opentofu is not available' {
            $result = Invoke-OpenTofu init -ErrorAction SilentlyContinue

            $result | Should -BeNullOrEmpty
        }
    }

    Context 'Tool available' {
        It 'Calls tofu with arguments' {
            Setup-CapturingCommandMock -CommandName 'tofu' -Output 'Init output'

            Invoke-OpenTofu init -ErrorAction SilentlyContinue | Out-Null

            $args = Get-TestCommandInvocationArgsFlat
            $args | Should -Contain 'init'
            $global:TestCommandInvocationCaptures.Count | Should -Be 1
        }

        It 'Calls tofu with plan command' {
            Setup-CapturingCommandMock -CommandName 'tofu' -Output 'Plan output'

            Invoke-OpenTofu plan -ErrorAction SilentlyContinue | Out-Null

            $args = Get-TestCommandInvocationArgsFlat
            $args | Should -Contain 'plan'
        }

        It 'Handles opentofu execution errors' {
            Set-TestCommandThrowingMock -CommandName 'tofu' -Message 'Command not found'

            { Invoke-OpenTofu plan -ErrorAction Stop } | Should -Throw
        }
    }
}
