<#
tests/unit/profile-ollama-fragment-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/ollama.ps1'
}
Describe 'profile.d/ollama.ps1 extended scenarios' {
    It 'Declares standard tier and PowerShell.Profile.Ollama module notes' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Tier: standard'
        $c | Should -Match 'PowerShell.Profile.Ollama'
    }
    It 'Defines Invoke-Ollama guarded by Test-CachedCommand ollama' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Invoke-Ollama'
        $c | Should -Match 'Test-CachedCommand ollama'
        $c | Should -Match 'Invoke-MissingToolWarning'
    }
    It 'Registers ol and ol-run Ollama aliases' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match "Set-AgentModeAlias -Name 'ol'"
        $c | Should -Match "Set-AgentModeAlias -Name 'ol-run'"
    }
}
