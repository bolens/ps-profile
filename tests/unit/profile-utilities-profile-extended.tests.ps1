<#
tests/unit/profile-utilities-profile-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/utilities-modules/system/utilities-profile.ps1'
}
Describe 'profile.d/utilities-modules/system/utilities-profile.ps1 extended scenarios' {
    It 'Documents profile management utilities for reload and backup' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Profile management utility functions'
        $c | Should -Match 'Profile reloading, editing, backup'
    }
    It 'Defines Reload-Profile with Fast mode and PS_PROFILE_FAST_RELOAD support' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Reload-Profile'
        $c | Should -Match 'PS_PROFILE_FAST_RELOAD'
        $c | Should -Match 'PS_PROFILE_DEV_MODE'
    }
    It 'Registers reload, edit-profile, backup-profile, and list-functions aliases' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match "Set-AgentModeAlias -Name 'reload'"
        $c | Should -Match "Set-AgentModeAlias -Name 'edit-profile'"
        $c | Should -Match "Set-AgentModeAlias -Name 'backup-profile'"
        $c | Should -Match 'Reload-Fragment'
    }
}
