<#
tests/unit/profile-git-advanced-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/git-modules/core/git-advanced.ps1'
}
Describe 'profile.d/git-modules/core/git-advanced.ps1 extended scenarios' {
    It 'Documents advanced Git helpers with lazy initialization' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Advanced Git command functions'
        $c | Should -Match 'Clone, stash, rebase, submodule, clean, sync, undo'
    }
    It 'Defines Ensure-GitHelper for deferred helper registration' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Ensure-GitHelper'
        $c | Should -Match '__GitHelpersInitialized'
        $c | Should -Match 'Invoke-GitClone'
    }
    It 'Registers lazy Git helpers via Register-LazyFunction with gcl and gsync aliases' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Register-LazyFunction'
        $c | Should -Match "Register-LazyFunction -Name 'Invoke-GitClone'"
        $c | Should -Match "Register-LazyFunction -Name 'Sync-GitRepository'"
    }
}
