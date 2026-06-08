<#
tests/unit/profile-game-dev-fragment-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/game-dev.ps1'
}
Describe 'profile.d/game-dev.ps1 extended scenarios' {
    It 'Declares optional tier for game development tooling' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Tier: optional'
        $c | Should -Match 'Blockbench'
        $c | Should -Match 'Godot'
    }
    It 'Defines Launch-Blockbench for 3D model editing workflows' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Launch-Blockbench'
        $c | Should -Match 'Set-AgentModeFunction'
    }
    It 'Marks game-dev fragment loaded after registration' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match "FragmentName 'game-dev'"
        $c | Should -Match "Set-FragmentLoaded -FragmentName 'game-dev'"
    }
}
