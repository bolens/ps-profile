# ===============================================
# profile-ai-tools-ollama.tests.ps1
# Unit tests for Invoke-OllamaEnhanced function
# ===============================================

BeforeAll {
    $current = Get-Item $PSScriptRoot
    while ($null -ne $current) {
        $testSupportPath = Join-Path $current.FullName 'TestSupport.ps1'
        if (Test-Path -LiteralPath $testSupportPath) {
            . $testSupportPath
            break
        }
        if ($current.Name -eq 'tests' -or $current.Parent -eq $null) { break }
        $current = $current.Parent
    }
    $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
    . (Join-Path $script:ProfileDir 'bootstrap.ps1')
    . (Join-Path $script:ProfileDir 'ai-tools.ps1')
}

Describe 'ai-tools.ps1 - Invoke-OllamaEnhanced' {
    BeforeEach {
        Clear-TestCommandInvocationCapture

        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }

        Set-TestCommandAvailabilityState -CommandName 'ollama' -Available $false
        Remove-Item -Path Function:\ollama -Force -ErrorAction SilentlyContinue
        Remove-Item -Path Function:\global:ollama -Force -ErrorAction SilentlyContinue
    }

    Context 'Tool not available' {
        It 'Returns null when ollama is not available' {
            Set-TestCommandAvailabilityState -CommandName 'ollama' -Available $false

            $result = Invoke-OllamaEnhanced -Arguments @('list') -ErrorAction SilentlyContinue

            $result | Should -BeNullOrEmpty
        }
    }

    Context 'Tool available' {
        It 'Calls ollama with correct arguments' {
            Setup-CapturingCommandMock -CommandName 'ollama' -Output 'NAME    ID      SIZE    MODIFIED'

            $result = Invoke-OllamaEnhanced -Arguments @('list')

            $result | Should -Not -BeNullOrEmpty
            $args = Get-TestCommandInvocationArgs
            $args | Should -Contain 'list'
        }

        It 'Handles ollama execution errors' {
            Set-TestCommandThrowingMock -CommandName 'ollama' -Message 'ollama: command failed'

            { Invoke-OllamaEnhanced -Arguments @('invalid-command') } | Should -Throw '*ollama*'
        }
    }
}
