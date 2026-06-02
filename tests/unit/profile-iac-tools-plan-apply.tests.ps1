# ===============================================
# profile-iac-tools-plan-apply.tests.ps1
# Unit tests for Plan-Infrastructure and Apply-Infrastructure functions
# ===============================================

BeforeAll {
    . (Join-Path $PSScriptRoot '..\TestSupport.ps1')
    $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
    . (Join-Path $script:ProfileDir 'bootstrap.ps1')
    . (Join-Path $script:ProfileDir 'iac-tools.ps1')
}

Describe 'iac-tools.ps1 - Plan-Infrastructure' {
    BeforeEach {
        Clear-TestCommandInvocationCapture

        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }

        Mark-TestCommandsUnavailable -CommandNames @('terraform', 'tofu')
    }

    Context 'Tool not available' {
        It 'Returns null when neither terraform nor opentofu is available' {
            $result = Plan-Infrastructure -ErrorAction SilentlyContinue

            $result | Should -BeNullOrEmpty
        }
    }

    Context 'terraform available' {
        BeforeEach {
            Mark-TestCommandsUnavailable -CommandNames 'tofu'
        }

        It 'Calls terraform plan with default settings' {
            Setup-CapturingCommandMock -CommandName 'terraform' -Output 'Plan output'
            Mark-TestCommandsUnavailable -CommandNames 'tofu'

            $result = Plan-Infrastructure -ErrorAction SilentlyContinue

            $args = Get-TestCommandInvocationArgsFlat
            $args | Should -Contain 'plan'
            $result | Should -Be 'Plan output'
        }

        It 'Calls terraform plan with output file' {
            Setup-CapturingCommandMock -CommandName 'terraform' -Output 'Plan output'
            Mark-TestCommandsUnavailable -CommandNames 'tofu'

            Plan-Infrastructure -OutputFile 'plan.out' -ErrorAction SilentlyContinue | Out-Null

            $args = Get-TestCommandInvocationArgsFlat
            $args | Should -Contain '-out'
            $args | Should -Contain 'plan.out'
        }

        It 'Calls terraform plan with additional arguments' {
            Setup-CapturingCommandMock -CommandName 'terraform' -Output 'Plan output'
            Mark-TestCommandsUnavailable -CommandNames 'tofu'

            Plan-Infrastructure -Tool 'terraform' '-detailed-exitcode' -ErrorAction SilentlyContinue | Out-Null

            $args = Get-TestCommandInvocationArgsFlat
            $args | Should -Contain '-detailed-exitcode'
        }
    }

    Context 'opentofu fallback' {
        It 'Calls tofu plan when terraform not available' {
            Setup-CapturingCommandMock -CommandName 'tofu' -Output 'Plan output'
            Mark-TestCommandsUnavailable -CommandNames 'terraform'

            Test-CachedCommand 'terraform' | Should -Be $false
            Test-CachedCommand 'tofu' | Should -Be $true

            $result = Plan-Infrastructure -ErrorAction SilentlyContinue

            $global:TestCommandInvocationCaptures.Count | Should -Be 1
            $args = Get-TestCommandInvocationArgsFlat
            $args | Should -Contain 'plan'
            $result | Should -Be 'Plan output'
        }

        It 'Calls tofu plan when explicitly requested' {
            Setup-CapturingCommandMock -CommandName 'tofu' -Output 'Plan output'
            Setup-AvailableCommandMock -CommandName 'terraform'

            Plan-Infrastructure -Tool 'opentofu' -ErrorAction SilentlyContinue | Out-Null

            $args = Get-TestCommandInvocationArgsFlat
            $args | Should -Contain 'plan'
        }
    }
}

Describe 'iac-tools.ps1 - Apply-Infrastructure' {
    BeforeEach {
        Clear-TestCommandInvocationCapture

        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }

        Mark-TestCommandsUnavailable -CommandNames @('terraform', 'tofu')
    }

    Context 'Tool not available' {
        It 'Returns null when neither terraform nor opentofu is available' {
            $result = Apply-Infrastructure -ErrorAction SilentlyContinue -Confirm:$false

            $result | Should -BeNullOrEmpty
        }
    }

    Context 'terraform available' {
        BeforeEach {
            Mark-TestCommandsUnavailable -CommandNames 'tofu'
        }

        It 'Calls terraform apply with default settings' {
            Setup-CapturingCommandMock -CommandName 'terraform' -Output 'Apply output'
            Mark-TestCommandsUnavailable -CommandNames 'tofu'

            $result = Apply-Infrastructure -ErrorAction SilentlyContinue -Confirm:$false

            $args = Get-TestCommandInvocationArgsFlat
            $args | Should -Contain 'apply'
            $result | Should -Be 'Apply output'
        }

        It 'Calls terraform apply with auto-approve' {
            Setup-CapturingCommandMock -CommandName 'terraform' -Output 'Apply output'
            Mark-TestCommandsUnavailable -CommandNames 'tofu'

            Apply-Infrastructure -AutoApprove -ErrorAction SilentlyContinue -Confirm:$false | Out-Null

            $args = Get-TestCommandInvocationArgsFlat
            $args | Should -Contain '-auto-approve'
        }

        It 'Calls terraform apply with plan file' {
            Setup-CapturingCommandMock -CommandName 'terraform' -Output 'Apply output'
            Mark-TestCommandsUnavailable -CommandNames 'tofu'

            Apply-Infrastructure -PlanFile 'plan.out' -ErrorAction SilentlyContinue -Confirm:$false | Out-Null

            $args = Get-TestCommandInvocationArgsFlat
            $args | Should -Contain 'plan.out'
        }
    }
}
