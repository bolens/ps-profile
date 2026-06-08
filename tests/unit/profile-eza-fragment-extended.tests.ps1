<#
tests/unit/profile-eza-fragment-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/eza.ps1'
}
Describe 'profile.d/eza.ps1 extended scenarios' {
    It 'Declares standard tier and requires Test-CachedCommand eza' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Tier: standard'
        $c | Should -Match 'Test-CachedCommand eza'
    }
    It 'Replaces ls and ll aliases with eza-backed listing functions' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Get-ChildItemEza'
        $c | Should -Match "Set-AgentModeAlias -Name 'ls'"
        $c | Should -Match "Set-AgentModeAlias -Name 'll'"
    }
    It 'Provides tree and git-aware listing aliases lt and lg' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Get-ChildItemEzaTree'
        $c | Should -Match "Set-AgentModeAlias -Name 'lt'"
        $c | Should -Match "Set-AgentModeAlias -Name 'lg'"
    }
}
