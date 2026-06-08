<#
tests/unit/profile-git-github-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/git-modules/integrations/git-github.ps1'
}
Describe 'profile.d/git-modules/integrations/git-github.ps1 extended scenarios' {
    It 'Documents GitHub CLI pull request helper functions' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'GitHub CLI helper functions'
        $c | Should -Match 'GitHub pull request operations'
    }
    It 'Defines New-GitHubPullRequest and Show-GitHubPullRequest guarded by gh' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'New-GitHubPullRequest'
        $c | Should -Match 'Show-GitHubPullRequest'
        $c | Should -Match 'Test-CachedCommand gh'
        $c | Should -Match 'gh pr create'
    }
    It 'Registers prc and prv GitHub pull request aliases' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match "Set-AgentModeAlias -Name 'prc'"
        $c | Should -Match "Set-AgentModeAlias -Name 'prv'"
    }
}
