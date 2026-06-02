# ===============================================
# profile-ai-tools-koboldcpp.tests.ps1
# Unit tests for Invoke-KoboldCpp function
# ===============================================

BeforeAll {
    . (Join-Path $PSScriptRoot '..\TestSupport.ps1')
    $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
    . (Join-Path $script:ProfileDir 'bootstrap.ps1')
    . (Join-Path $script:ProfileDir 'ai-tools.ps1')
}

Describe 'ai-tools.ps1 - Invoke-KoboldCpp' {
    BeforeEach {
        Clear-TestCommandInvocationCapture

        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }

        Set-TestCommandAvailabilityState -CommandName 'koboldcpp' -Available $false
        Remove-Item -Path Function:\koboldcpp -Force -ErrorAction SilentlyContinue
        Remove-Item -Path Function:\global:koboldcpp -Force -ErrorAction SilentlyContinue
        Remove-Item -Path Alias:\koboldcpp -Force -ErrorAction SilentlyContinue
        Remove-Item -Path Alias:\global:koboldcpp -Force -ErrorAction SilentlyContinue
    }

    Context 'Tool not available' {
        It 'Returns null when koboldcpp is not available' {
            Set-TestCommandAvailabilityState -CommandName 'koboldcpp' -Available $false

            $result = Invoke-KoboldCpp -Arguments @('--help') -ErrorAction SilentlyContinue

            $result | Should -BeNullOrEmpty
        }
    }

    Context 'Tool available' {
        It 'Calls koboldcpp with correct arguments' {
            Setup-CapturingCommandMock -CommandName 'koboldcpp' -Output 'KoboldCpp help'

            $result = Invoke-KoboldCpp -Arguments @('--help')

            $result | Should -Not -BeNullOrEmpty
            $args = Get-TestCommandInvocationArgs
            $args | Should -Contain '--help'
        }

        It 'Handles koboldcpp execution errors' {
            Set-TestCommandThrowingMock -CommandName 'koboldcpp' -Message 'koboldcpp: command failed'

            { Invoke-KoboldCpp -Arguments @('invalid-command') } | Should -Throw '*koboldcpp*'
        }
    }
}
