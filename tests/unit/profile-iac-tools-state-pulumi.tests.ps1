# ===============================================
# profile-iac-tools-state-pulumi.tests.ps1
# Unit tests for Get-TerraformState and Invoke-Pulumi functions
# ===============================================

BeforeAll {
    . (Join-Path $PSScriptRoot '..\TestSupport.ps1')
    $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
    . (Join-Path $script:ProfileDir 'bootstrap.ps1')
    . (Join-Path $script:ProfileDir 'iac-tools.ps1')
}

Describe 'iac-tools.ps1 - Get-TerraformState' {
    BeforeEach {
        Clear-TestCommandInvocationCapture

        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }

        Mark-TestCommandsUnavailable -CommandNames @('terraform', 'tofu')
    }

    Context 'Tool not available' {
        It 'Returns null when neither terraform nor opentofu is available' {
            $result = Get-TerraformState -ErrorAction SilentlyContinue

            $result | Should -BeNullOrEmpty
        }
    }

    Context 'terraform available' {
        BeforeEach {
            Mark-TestCommandsUnavailable -CommandNames 'tofu'
        }

        It 'Calls terraform state show with default settings' {
            Setup-CapturingCommandMock -CommandName 'terraform' -Output 'State output'
            Mark-TestCommandsUnavailable -CommandNames 'tofu'

            $result = Get-TerraformState -ErrorAction SilentlyContinue

            $args = Get-TestCommandInvocationArgsFlat
            $args | Should -Contain 'state'
            $args | Should -Contain 'show'
            $result | Should -Be 'State output'
        }

        It 'Calls terraform state show with resource address' {
            Setup-CapturingCommandMock -CommandName 'terraform' -Output 'Resource state'
            Mark-TestCommandsUnavailable -CommandNames 'tofu'

            Get-TerraformState -ResourceAddress 'aws_instance.web' -ErrorAction SilentlyContinue | Out-Null

            $args = Get-TestCommandInvocationArgsFlat
            $args | Should -Contain 'aws_instance.web'
        }

        It 'Calls terraform state show with JSON format' {
            Setup-CapturingCommandMock -CommandName 'terraform' -Output '{"state": "json"}'
            Mark-TestCommandsUnavailable -CommandNames 'tofu'

            Get-TerraformState -OutputFormat 'json' -ErrorAction SilentlyContinue | Out-Null

            $args = Get-TestCommandInvocationArgsFlat
            $args | Should -Contain '-json'
        }

        It 'Calls terraform state show with state file' {
            Setup-CapturingCommandMock -CommandName 'terraform' -Output 'State output'
            Mark-TestCommandsUnavailable -CommandNames 'tofu'

            Get-TerraformState -StateFile 'custom.tfstate' -ErrorAction SilentlyContinue | Out-Null

            $args = Get-TestCommandInvocationArgsFlat
            $args | Should -Contain '-state'
            $args | Should -Contain 'custom.tfstate'
        }
    }

    Context 'opentofu fallback' {
        It 'Calls tofu state show when terraform not available' {
            Setup-CapturingCommandMock -CommandName 'tofu' -Output 'State output'
            Mark-TestCommandsUnavailable -CommandNames 'terraform'

            Test-CachedCommand 'terraform' | Should -Be $false
            Test-CachedCommand 'tofu' | Should -Be $true

            $result = Get-TerraformState -ErrorAction SilentlyContinue

            $global:TestCommandInvocationCaptures.Count | Should -Be 1
            $args = Get-TestCommandInvocationArgsFlat
            $args | Should -Contain 'state'
            $args | Should -Contain 'show'
            $result | Should -Be 'State output'
        }
    }
}

Describe 'iac-tools.ps1 - Invoke-Pulumi' {
    BeforeEach {
        Clear-TestCommandInvocationCapture

        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }

        Set-TestCommandAvailabilityState -CommandName 'pulumi' -Available $false
        Remove-Item -Path 'Function:\pulumi' -Force -ErrorAction SilentlyContinue
        Remove-Item -Path 'Function:\global:pulumi' -Force -ErrorAction SilentlyContinue
    }

    Context 'Tool not available' {
        It 'Returns null when pulumi is not available' {
            $result = Invoke-Pulumi preview -ErrorAction SilentlyContinue

            $result | Should -BeNullOrEmpty
        }
    }

    Context 'Tool available' {
        It 'Calls pulumi with arguments' {
            Setup-CapturingCommandMock -CommandName 'pulumi' -Output 'Preview output'

            Invoke-Pulumi preview -ErrorAction SilentlyContinue | Out-Null

            $args = Get-TestCommandInvocationArgsFlat
            $args | Should -Contain 'preview'
            $global:TestCommandInvocationCaptures.Count | Should -Be 1
        }

        It 'Calls pulumi with multiple arguments' {
            Setup-CapturingCommandMock -CommandName 'pulumi' -Output 'Up output'

            Invoke-Pulumi up --yes -ErrorAction SilentlyContinue | Out-Null

            $args = Get-TestCommandInvocationArgsFlat
            $args | Should -Contain 'up'
            $args | Should -Contain '--yes'
        }

        It 'Handles pulumi execution errors' {
            Set-TestCommandThrowingMock -CommandName 'pulumi' -Message 'Command not found'

            { Invoke-Pulumi preview -ErrorAction Stop } | Should -Throw
        }
    }
}
