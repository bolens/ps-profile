<#
tests/unit/profile-ai-tools-fragment-extended.tests.ps1
#>
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
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/ai-tools.ps1'
}
Describe 'profile.d/ai-tools.ps1 extended scenarios' {
    It 'Declares standard tier for AI and LLM tool wrappers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Tier: standard'
        $c | Should -Match 'AI and LLM tools'
    }
    It 'Defines Invoke-OllamaEnhanced with Test-FragmentLoaded idempotency' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Invoke-OllamaEnhanced'
        $c | Should -Match "Test-FragmentLoaded -FragmentName 'ai-tools'"
        $c | Should -Match "Test-CachedCommand 'ollama'"
    }
    It 'Marks ai-tools fragment loaded after registration' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match "Set-FragmentLoaded -FragmentName 'ai-tools'"
        $c | Should -Match "Set-AgentModeAlias -Name 'ollama-enhanced'"
    }
}
