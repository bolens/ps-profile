# ===============================================
# profile-ai-tools-llamafile.tests.ps1
# Unit tests for Invoke-Llamafile function
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

Describe 'ai-tools.ps1 - Invoke-Llamafile' {
    BeforeEach {
        Clear-TestCommandInvocationCapture

        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }

        Set-TestCommandAvailabilityState -CommandName 'llamafile' -Available $false
        Remove-Item -Path Function:\llamafile -Force -ErrorAction SilentlyContinue
        Remove-Item -Path Function:\global:llamafile -Force -ErrorAction SilentlyContinue
        Remove-Item -Path Alias:\llamafile -Force -ErrorAction SilentlyContinue
        Remove-Item -Path Alias:\global:llamafile -Force -ErrorAction SilentlyContinue
    }

    Context 'Tool not available' {
        It 'Returns null when llamafile is not available' {
            Set-TestCommandAvailabilityState -CommandName 'llamafile' -Available $false

            $result = Invoke-Llamafile -Arguments @('--help') -ErrorAction SilentlyContinue

            $result | Should -BeNullOrEmpty
        }
    }

    Context 'Tool available' {
        It 'Calls llamafile with correct arguments' {
            Setup-CapturingCommandMock -CommandName 'llamafile' -Output 'Llamafile help'

            $result = Invoke-Llamafile -Arguments @('--help')

            $result | Should -Not -BeNullOrEmpty
            $args = Get-TestCommandInvocationArgs
            $args | Should -Contain '--help'
        }

        It 'Includes Model parameter in arguments' {
            Setup-CapturingCommandMock -CommandName 'llamafile' -Output 'Model output'

            $modelPath = 'test-model.llamafile'
            $result = Invoke-Llamafile -Model $modelPath

            $result | Should -Not -BeNullOrEmpty
            $args = Get-TestCommandInvocationArgs
            $args | Should -Contain $modelPath
        }

        It 'Includes Prompt parameter in arguments' {
            Setup-CapturingCommandMock -CommandName 'llamafile' -Output 'Prompt response'

            $prompt = 'Hello, world!'
            $result = Invoke-Llamafile -Prompt $prompt

            $result | Should -Not -BeNullOrEmpty
            $args = Get-TestCommandInvocationArgs
            $args | Should -Contain '--prompt'
            $args | Should -Contain $prompt
        }

        It 'Combines Model, Prompt, and Arguments' {
            Setup-CapturingCommandMock -CommandName 'llamafile' -Output 'Combined output'

            $result = Invoke-Llamafile -Model 'model.llamafile' -Prompt 'Test prompt' -Arguments @('--ctx-size', '2048')

            $result | Should -Not -BeNullOrEmpty
            $args = Get-TestCommandInvocationArgs
            $args | Should -Contain 'model.llamafile'
            $args | Should -Contain '--prompt'
            $args | Should -Contain 'Test prompt'
            $args | Should -Contain '--ctx-size'
            $args | Should -Contain '2048'
        }

        It 'Handles llamafile execution errors' {
            Set-TestCommandThrowingMock -CommandName 'llamafile' -Message 'llamafile: command failed'

            { Invoke-Llamafile -Arguments @('invalid-command') } | Should -Throw '*llamafile*'
        }
    }
}
