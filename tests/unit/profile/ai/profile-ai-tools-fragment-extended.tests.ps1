# ===============================================
# profile-ai-tools-fragment-extended.tests.ps1
# Execution tests for ai-tools.ps1 fragment behavior
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
    $fragmentIdempotencyPath = Get-TestPath -RelativePath 'scripts/lib/fragment/FragmentIdempotency.psm1' -StartPath $PSScriptRoot -EnsureExists
    Import-Module $fragmentIdempotencyPath -DisableNameChecking -ErrorAction Stop -Force
    . (Join-Path $script:ProfileDir 'bootstrap.ps1')
}

function script:Reset-AiToolsFragmentState {
    Clear-FragmentLoaded -FragmentName 'ai-tools' -ErrorAction SilentlyContinue
}

Describe 'profile.d/ai-tools.ps1 extended scenarios' {
    BeforeEach {
        Reset-AiToolsFragmentState
    }

    It 'Registers Ollama enhanced helpers and marks the fragment loaded' {
        . (Join-Path $script:ProfileDir 'ai-tools.ps1')

        Get-Command Invoke-OllamaEnhanced -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command ollama-enhanced -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Test-FragmentLoaded -FragmentName 'ai-tools' | Should -Be $true
    }

    It 'Invoke-OllamaEnhanced warns when ollama is unavailable' {
        . (Join-Path $script:ProfileDir 'ai-tools.ps1')

        Set-TestCommandAvailabilityState -CommandName 'ollama' -Available $false
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }
        if ($global:MissingToolWarnings) {
            $null = $global:MissingToolWarnings.TryRemove('ollama', [ref]$null)
        }

        $output = & { Invoke-OllamaEnhanced -Arguments @('list') } 2>&1 3>&1 | Out-String
        Assert-TestMissingToolWarning -Output $output -Pattern 'ollama not found'
    }

    It 'Skips re-initialization when ai-tools is already loaded' {
        . (Join-Path $script:ProfileDir 'ai-tools.ps1')
        $firstOllama = Get-Command Invoke-OllamaEnhanced -ErrorAction Stop

        . (Join-Path $script:ProfileDir 'ai-tools.ps1')

        (Get-Command Invoke-OllamaEnhanced -ErrorAction Stop).ScriptBlock.ToString() |
            Should -Be $firstOllama.ScriptBlock.ToString()
    }
}
