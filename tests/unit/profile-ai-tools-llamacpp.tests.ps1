# ===============================================
# profile-ai-tools-llamacpp.tests.ps1
# Unit tests for Invoke-LlamaCpp function
# ===============================================

BeforeAll {
    . (Join-Path $PSScriptRoot '..\TestSupport.ps1')
    $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
    . (Join-Path $script:ProfileDir 'bootstrap.ps1')
    . (Join-Path $script:ProfileDir 'ai-tools.ps1')
}

Describe 'ai-tools.ps1 - Invoke-LlamaCpp' {
    BeforeEach {
        Clear-TestCommandInvocationCapture

        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }

        foreach ($variant in @('llama-cpp-cuda', 'llama-cpp', 'llama.cpp')) {
            Set-TestCommandAvailabilityState -CommandName $variant -Available $false
            Remove-Item -Path "Function:\$variant" -Force -ErrorAction SilentlyContinue
            Remove-Item -Path "Function:\global:$variant" -Force -ErrorAction SilentlyContinue
        }

        Remove-Item -Path Alias:\llama-cpp -Force -ErrorAction SilentlyContinue
        Remove-Item -Path Alias:\global:llama-cpp -Force -ErrorAction SilentlyContinue
    }

    Context 'Tool not available' {
        It 'Returns null when no llama-cpp variant is available' {
            Set-TestCommandAvailabilityState -CommandName 'llama-cpp-cuda' -Available $false
            Set-TestCommandAvailabilityState -CommandName 'llama-cpp' -Available $false
            Set-TestCommandAvailabilityState -CommandName 'llama.cpp' -Available $false

            $result = Invoke-LlamaCpp -Arguments @('--help') -ErrorAction SilentlyContinue

            $result | Should -BeNullOrEmpty
        }
    }

    Context 'Tool available - llama-cpp-cuda' {
        It 'Prefers llama-cpp-cuda when available' {
            Set-TestCommandAvailabilityState -CommandName 'llama-cpp' -Available $false
            Setup-CapturingCommandMock -CommandName 'llama-cpp-cuda' -Output 'llama-cpp-cuda help'

            $result = Invoke-LlamaCpp -Arguments @('--help')

            $result | Should -Not -BeNullOrEmpty
            $args = Get-TestCommandInvocationArgs
            $args | Should -Contain '--help'
        }
    }

    Context 'Tool available - llama-cpp' {
        It 'Falls back to llama-cpp when llama-cpp-cuda is not available' {
            Set-TestCommandAvailabilityState -CommandName 'llama-cpp-cuda' -Available $false
            Setup-CapturingCommandMock -CommandName 'llama-cpp' -Output 'llama-cpp help'

            $result = Invoke-LlamaCpp -Arguments @('--help')

            $result | Should -Not -BeNullOrEmpty
            $args = Get-TestCommandInvocationArgs
            $args | Should -Contain '--help'
        }
    }

    Context 'Tool available - llama.cpp' {
        It 'Falls back to llama.cpp when other variants are not available' {
            Set-TestCommandAvailabilityState -CommandName 'llama-cpp-cuda' -Available $false
            Set-TestCommandAvailabilityState -CommandName 'llama-cpp' -Available $false
            Setup-CapturingCommandMock -CommandName 'llama.cpp' -Output 'llama.cpp help'

            $result = Invoke-LlamaCpp -Arguments @('--help')

            $result | Should -Not -BeNullOrEmpty
            $args = Get-TestCommandInvocationArgs
            $args | Should -Contain '--help'
        }
    }

    Context 'Error handling' {
        It 'Handles llama-cpp execution errors' {
            Set-TestCommandAvailabilityState -CommandName 'llama-cpp' -Available $false
            Set-TestCommandThrowingMock -CommandName 'llama-cpp-cuda' -Message 'llama-cpp-cuda: command failed'

            { Invoke-LlamaCpp -Arguments @('invalid-command') } | Should -Throw '*llama-cpp-cuda*'
        }
    }
}
