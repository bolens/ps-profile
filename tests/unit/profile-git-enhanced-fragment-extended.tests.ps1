<#
tests/unit/profile-git-enhanced-fragment-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/git-enhanced.ps1'
}
Describe 'profile.d/git-enhanced.ps1 extended scenarios' {
    It 'Declares standard tier depending on git fragment' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Tier: standard'
        $c | Should -Match 'Dependencies: bootstrap, env, git'
    }
    It 'Loads enhanced git modules from git-modules/enhanced' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'git-changelog\.ps1'
        $c | Should -Match 'git-gui\.ps1'
        $c | Should -Match 'git-workflow\.ps1'
    }
    It 'Uses Import-FragmentModules with manual fallback dot-sourcing' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Import-FragmentModules'
        $c | Should -Match "Set-FragmentLoaded -FragmentName 'git-enhanced'"
    }
}
