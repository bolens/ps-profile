<#
tests/unit/profile-game-emulators-fragment-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/game-emulators.ps1'
}
Describe 'profile.d/game-emulators.ps1 extended scenarios' {
    It 'Declares optional tier covering multi-system emulator launchers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Tier: optional'
        $c | Should -Match 'Dolphin'
        $c | Should -Match 'RetroArch'
    }
    It 'Defines Start-Dolphin with ROM extension routing table' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Start-Dolphin'
        $c | Should -Match '\.gcm''  = ''Start-Dolphin'''
    }
    It 'Marks game-emulators fragment loaded after helper registration' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match "FragmentName 'game-emulators'"
        $c | Should -Match "Set-FragmentLoaded -FragmentName 'game-emulators'"
    }
}
