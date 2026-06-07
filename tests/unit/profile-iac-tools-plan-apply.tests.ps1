# ===============================================
# profile-iac-tools-plan-apply.tests.ps1
# Unit tests for Get-TerraformPlan and Invoke-TerraformApply functions
# ===============================================

BeforeAll {
    . (Join-Path $PSScriptRoot '..\TestSupport.ps1')
    $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
    . (Join-Path $script:ProfileDir 'bootstrap.ps1')
    . (Join-Path $script:ProfileDir 'terraform.ps1')
}

Describe 'terraform.ps1 - Get-TerraformPlan' {
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
            $result = Get-TerraformPlan -ErrorAction SilentlyContinue

            $result | Should -BeNullOrEmpty
        }
    }

    Context 'terraform available' {
        It 'Calls terraform plan with default settings' {
            Setup-CapturingCommandMock -CommandName 'terraform' -Output 'Plan output'

            $result = Get-TerraformPlan -ErrorAction SilentlyContinue

            $args = Get-TestCommandInvocationArgsFlat
            $args | Should -Contain 'plan'
            $result | Should -Be 'Plan output'
        }

        It 'Calls terraform plan with output file' {
            Setup-CapturingCommandMock -CommandName 'terraform' -Output 'Plan output'

            Get-TerraformPlan '-out=plan.out' -ErrorAction SilentlyContinue | Out-Null

            $args = Get-TestCommandInvocationArgsFlat
            $args | Should -Contain '-out=plan.out'
        }

        It 'Calls terraform plan with additional arguments' {
            Setup-CapturingCommandMock -CommandName 'terraform' -Output 'Plan output'

            Get-TerraformPlan '-detailed-exitcode' -ErrorAction SilentlyContinue | Out-Null

            $args = Get-TestCommandInvocationArgsFlat
            $args | Should -Contain '-detailed-exitcode'
        }
    }
}

Describe 'terraform.ps1 - Invoke-TerraformApply' {
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
            $result = Invoke-TerraformApply -ErrorAction SilentlyContinue

            $result | Should -BeNullOrEmpty
        }
    }

    Context 'terraform available' {
        It 'Calls terraform apply with default settings' {
            Setup-CapturingCommandMock -CommandName 'terraform' -Output 'Apply output'

            $result = Invoke-TerraformApply -ErrorAction SilentlyContinue

            $args = Get-TestCommandInvocationArgsFlat
            $args | Should -Contain 'apply'
            $result | Should -Be 'Apply output'
        }

        It 'Calls terraform apply with auto-approve' {
            Setup-CapturingCommandMock -CommandName 'terraform' -Output 'Apply output'

            Invoke-TerraformApply '-auto-approve' -ErrorAction SilentlyContinue | Out-Null

            $args = Get-TestCommandInvocationArgsFlat
            $args | Should -Contain '-auto-approve'
        }

        It 'Calls terraform apply with plan file' {
            Setup-CapturingCommandMock -CommandName 'terraform' -Output 'Apply output'

            Invoke-TerraformApply 'plan.out' -ErrorAction SilentlyContinue | Out-Null

            $args = Get-TestCommandInvocationArgsFlat
            $args | Should -Contain 'plan.out'
        }
    }
}
