<#
tests/unit/profile-git-fragment-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/git.ps1'
}
Describe 'profile.d/git.ps1 extended scenarios' {
    It 'Declares essential tier depending on bootstrap and env' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Tier: essential'
        $c | Should -Match 'Dependencies: bootstrap, env'
    }
    It 'Uses Ensure-Git with Load-EnsureModules for deferred git-modules loading' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Ensure-Git'
        $c | Should -Match 'git-modules'
    }
    It 'Registers lazy git helpers with Register-LazyFunction aliases' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Register-LazyFunction'
        $c | Should -Match "Alias 'gs'"
    }
}
