<#
tests/unit/profile-beads-fragment-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/beads.ps1'
}
Describe 'profile.d/beads.ps1 extended scenarios' {
    It 'Declares standard tier for Beads issue tracker integration' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Tier: standard'
        $c | Should -Match 'Beads issue tracker'
    }
    It 'Defines Invoke-Beads guarded by Test-CachedCommand bd' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Invoke-Beads'
        $c | Should -Match "Test-CachedCommand 'bd'"
        $c | Should -Match "Test-FragmentLoaded -FragmentName 'beads'"
    }
    It 'Registers bd alias and marks beads fragment loaded' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match "Set-AgentModeAlias -Name 'bd'"
        $c | Should -Match "Set-FragmentLoaded -FragmentName 'beads'"
    }
}
