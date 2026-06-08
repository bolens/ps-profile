<#
tests/unit/profile-dev-fragment-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/dev.ps1'
}
Describe 'profile.d/dev.ps1 extended scenarios' {
    It 'Declares standard tier for development shortcuts' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Tier: standard'
        $c | Should -Match 'Environment: web, development'
    }
    It 'Registers idempotent docker wrapper functions guarded by Test-Path Function' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match "Test-Path Function:d"
        $c | Should -Match 'docker @Args'
    }
    It 'Provides npm and python shortcut wrappers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match "Test-Path Function:n"
        $c | Should -Match "Test-Path Function:py"
    }
}
