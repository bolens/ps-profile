<#
tests/unit/profile-scoop-completion-fragment-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/scoop-completion.ps1'
}
Describe 'profile.d/scoop-completion.ps1 extended scenarios' {
    It 'Declares essential tier for lazy Scoop tab completion' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Tier: essential'
        $c | Should -Match 'Dependencies: bootstrap, env'
    }
    It 'Uses Get-ScoopCompletionPath and Enable-ScoopCompletion lazy loader' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Get-ScoopCompletionPath'
        $c | Should -Match 'Enable-ScoopCompletion'
        $c | Should -Match 'ScoopCompletionLoaded'
    }
    It 'Guards idempotency with global ScoopCompletionLoaded variable' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match "Get-Variable -Name 'ScoopCompletionLoaded'"
        $c | Should -Match 'Scoop-Completion.psd1'
    }
}
