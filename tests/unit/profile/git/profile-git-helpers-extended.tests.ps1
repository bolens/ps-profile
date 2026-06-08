<#
tests/unit/profile-git-helpers-extended.tests.ps1
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
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/git-modules/core/git-helpers.ps1'
}
Describe 'profile.d/git-modules/core/git-helpers.ps1 extended scenarios' {
    It 'Documents Git helper utilities for repository context checks' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Git helper utility functions'
        $c | Should -Match 'Repository context checks and command wrapper'
    }
    It 'Defines Test-GitRepositoryContext and Test-GitRepositoryHasCommits' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Test-GitRepositoryContext'
        $c | Should -Match 'Test-GitRepositoryHasCommits'
        $c | Should -Match "Test-CachedCommand git"
    }
    It 'Defines Invoke-GitCommand wrapper for git subcommands' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'function Invoke-GitCommand'
        $c | Should -Match 'rev-parse --is-inside-work-tree'
        $c | Should -Match 'show-ref --quiet HEAD'
    }
}
