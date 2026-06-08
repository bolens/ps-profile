<#
tests/unit/profile-git-gui-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/git-modules/enhanced/git-gui.ps1'
}
Describe 'profile.d/git-modules/enhanced/git-gui.ps1 extended scenarios' {
    It 'Declares standard tier for Git GUI tool launchers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Tier: standard'
        $c | Should -Match 'Tower, Kraken, GitButler, and Jujutsu'
    }
    It 'Defines Invoke-GitTower, Invoke-GitKraken, and Invoke-GitButler with tool checks' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Invoke-GitTower'
        $c | Should -Match 'Invoke-GitKraken'
        $c | Should -Match 'Invoke-GitButler'
        $c | Should -Match "Test-CachedCommand 'git-tower'"
    }
    It 'Registers git-tower and gitkraken aliases and marks git-gui loaded' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match "Set-AgentModeAlias -Name 'git-tower'"
        $c | Should -Match "Set-AgentModeAlias -Name 'gitkraken'"
        $c | Should -Match "Set-FragmentLoaded -FragmentName 'git-gui'"
    }
}
