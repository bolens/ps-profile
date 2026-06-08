# ===============================================
# profile-ai-tools-comfyui.tests.ps1
# Unit tests for Invoke-ComfyUI function
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

Describe 'ai-tools.ps1 - Invoke-ComfyUI' {
    BeforeEach {
        Clear-TestCommandInvocationCapture

        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }

        Set-TestCommandAvailabilityState -CommandName 'comfy' -Available $false
        Remove-Item -Path Function:\comfy -Force -ErrorAction SilentlyContinue
        Remove-Item -Path Function:\global:comfy -Force -ErrorAction SilentlyContinue
        Remove-Item -Path Alias:\comfy -Force -ErrorAction SilentlyContinue
        Remove-Item -Path Alias:\global:comfy -Force -ErrorAction SilentlyContinue
    }

    Context 'Tool not available' {
        It 'Returns null when comfy is not available' {
            Set-TestCommandAvailabilityState -CommandName 'comfy' -Available $false

            $result = Invoke-ComfyUI -Arguments @('install') -ErrorAction SilentlyContinue

            $result | Should -BeNullOrEmpty
        }
    }

    Context 'Tool available' {
        It 'Calls comfy with correct arguments' {
            Setup-CapturingCommandMock -CommandName 'comfy' -Output 'ComfyUI installed'

            $result = Invoke-ComfyUI -Arguments @('install')

            $result | Should -Not -BeNullOrEmpty
            $args = Get-TestCommandInvocationArgs
            $args | Should -Contain 'install'
        }

        It 'Handles comfy execution errors' {
            Set-TestCommandThrowingMock -CommandName 'comfy' -Message 'comfy: command failed'

            { Invoke-ComfyUI -Arguments @('invalid-command') } | Should -Throw '*comfy*'
        }
    }
}
