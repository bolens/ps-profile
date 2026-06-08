<#
tests/unit/profile-git-changelog-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/git-modules/enhanced/git-changelog.ps1'
}
Describe 'profile.d/git-modules/enhanced/git-changelog.ps1 extended scenarios' {
    It 'Declares standard tier for Git changelog helpers via git-cliff' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Tier: standard'
        $c | Should -Match 'New-GitChangelog via git-cliff'
    }
    It 'Defines New-GitChangelog guarded by Test-CachedCommand git-cliff' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'New-GitChangelog'
        $c | Should -Match "Test-CachedCommand 'git-cliff'"
        $c | Should -Match 'Invoke-MissingToolWarning'
    }
    It 'Registers git-cliff alias and marks git-changelog fragment loaded' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match "Set-AgentModeAlias -Name 'git-cliff'"
        $c | Should -Match "Set-FragmentLoaded -FragmentName 'git-changelog'"
    }
}
