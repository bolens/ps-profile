<#
tests/unit/profile-modules-fragment-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/modules.ps1'
}
Describe 'profile.d/modules.ps1 extended scenarios' {
    It 'Declares standard tier with bootstrap dependency' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Tier: standard'
        $c | Should -Match 'Dependencies: bootstrap, env'
    }
    It 'Uses Test-FragmentLoaded for idempotent module fragment loading' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Test-FragmentLoaded'
        $c | Should -Match "FragmentName 'modules'"
    }
    It 'Exposes Enable-PoshGit lazy import helper instead of eager Import-Module' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Enable-PoshGit'
        $c | Should -Match "Import-Module -Name 'posh-git'"
    }
}
