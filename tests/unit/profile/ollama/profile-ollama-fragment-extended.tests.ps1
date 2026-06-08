# ===============================================
# profile-ollama-fragment-extended.tests.ps1
# Execution tests for ollama.ps1 fragment behavior
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
    . (Join-Path $script:ProfileDir 'ollama.ps1')
}

Describe 'profile.d/ollama.ps1 extended scenarios' {
    It 'Registers Ollama model helpers and aliases' {
        Get-Command Invoke-Ollama -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Get-OllamaModelList -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command ol -ErrorAction Stop | Should -Not -BeNullOrEmpty
    }

    It 'Invoke-Ollama warns when ollama is unavailable' {
        Set-TestCommandAvailabilityState -CommandName 'ollama' -Available $false
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }
        if ($global:MissingToolWarnings) {
            $null = $global:MissingToolWarnings.TryRemove('ollama', [ref]$null)
        }

        $output = Invoke-Ollama --version 2>&1 3>&1 | Out-String
        Assert-TestMissingToolWarning -Output $output -Pattern 'ollama not found'
    }

    It 'Preserves existing ollama helper bodies on repeated fragment loads' {
        $firstOllama = Get-Command Invoke-Ollama -ErrorAction Stop

        . (Join-Path $script:ProfileDir 'ollama.ps1')

        (Get-Command Invoke-Ollama -ErrorAction Stop).ScriptBlock.ToString() |
            Should -Be $firstOllama.ScriptBlock.ToString()
    }
}
