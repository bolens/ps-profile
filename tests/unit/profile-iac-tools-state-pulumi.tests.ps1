# ===============================================
# profile-iac-tools-state-pulumi.tests.ps1
# Unit tests for Initialize-Terraform and Invoke-Terraform functions
# ===============================================

BeforeAll {
    . (Join-Path $PSScriptRoot '..\TestSupport.ps1')
    $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
    . (Join-Path $script:ProfileDir 'bootstrap.ps1')
    . (Join-Path $script:ProfileDir 'terraform.ps1')
}

Describe 'terraform.ps1 - Initialize-Terraform' {
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
            $result = Initialize-Terraform -ErrorAction SilentlyContinue

            $result | Should -BeNullOrEmpty
        }
    }

    Context 'terraform available' {
        It 'Calls terraform init with default settings' {
            Setup-CapturingCommandMock -CommandName 'terraform' -Output 'Init output'

            $result = Initialize-Terraform -ErrorAction SilentlyContinue

            $args = Get-TestCommandInvocationArgsFlat
            $args | Should -Contain 'init'
            $result | Should -Be 'Init output'
        }

        It 'Calls terraform init with upgrade flag' {
            Setup-CapturingCommandMock -CommandName 'terraform' -Output 'Init output'

            Initialize-Terraform '-upgrade' -ErrorAction SilentlyContinue | Out-Null

            $args = Get-TestCommandInvocationArgsFlat
            $args | Should -Contain '-upgrade'
        }
    }
}

Describe 'terraform.ps1 - Invoke-Terraform' {
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
            $result = Invoke-Terraform version -ErrorAction SilentlyContinue

            $result | Should -BeNullOrEmpty
        }
    }

    Context 'Tool available' {
        It 'Calls terraform with arguments' {
            Setup-CapturingCommandMock -CommandName 'terraform' -Output 'Terraform v1.0.0'

            Invoke-Terraform version -ErrorAction SilentlyContinue | Out-Null

            $args = Get-TestCommandInvocationArgsFlat
            $args | Should -Contain 'version'
            $global:TestCommandInvocationCaptures.Count | Should -Be 1
        }

        It 'Calls terraform with multiple arguments' {
            Setup-CapturingCommandMock -CommandName 'terraform' -Output 'State list output'

            Invoke-Terraform state list -ErrorAction SilentlyContinue | Out-Null

            $args = Get-TestCommandInvocationArgsFlat
            $args | Should -Contain 'state'
            $args | Should -Contain 'list'
        }

        It 'Handles terraform execution errors' {
            Set-TestCommandThrowingMock -CommandName 'terraform' -Message 'Command not found'

            { Invoke-Terraform version -ErrorAction Stop } | Should -Throw
        }
    }
}
