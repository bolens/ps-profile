<#
tests/unit/profile-volta-fragment-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/volta.ps1'
}
Describe 'profile.d/volta.ps1 extended scenarios' {
    It 'Declares standard tier guarded by volta availability' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Tier: standard'
        $c | Should -Match 'if \(Test-CachedCommand volta\)'
    }
    It 'Defines Install-VoltaTool for pinning Node npm and Yarn versions' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Install-VoltaTool'
        $c | Should -Match 'volta install'
    }
    It 'Registers voltainstall and voltaadd aliases' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match "Set-AgentModeAlias -Name 'voltainstall'"
        $c | Should -Match "Set-AgentModeAlias -Name 'voltaadd'"
    }
}
