<#
tests/unit/profile-git-workflow-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/git-modules/enhanced/git-workflow.ps1'
}
Describe 'profile.d/git-modules/enhanced/git-workflow.ps1 extended scenarios' {
    It 'Declares standard tier for Git workflow helpers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Tier: standard'
        $c | Should -Match 'Worktrees, sync, branch cleanup, stats'
    }
    It 'Defines New-GitWorktree, Sync-GitRepos, and Get-GitStats helpers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'New-GitWorktree'
        $c | Should -Match 'Sync-GitRepos'
        $c | Should -Match 'Get-GitStats'
        $c | Should -Match 'Clean-GitBranches'
    }
    It 'Marks git-workflow fragment loaded after registration' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match "Test-FragmentLoaded -FragmentName 'git-workflow'"
        $c | Should -Match "Set-FragmentLoaded -FragmentName 'git-workflow'"
    }
}
