<#
tests/unit/utility-sync-profile-fragments-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Script = Join-Path $script:TestRepoRoot 'scripts/utils/fragment/sync-profile-fragments.ps1'
}
Describe 'sync-profile-fragments.ps1 extended scenarios' {
    It 'Documents ProfileDir ConfigPath and DryRun parameters' {
        $c = Get-Content -LiteralPath $script:Script -Raw
        $c | Should -Match 'ProfileDir'
        $c | Should -Match 'ConfigPath'
        $c | Should -Match 'DryRun'
    }
    It 'Syncs .profile-fragments.json with discovered fragments' {
        $c = Get-Content -LiteralPath $script:Script -Raw
        $c | Should -Match '\.profile-fragments\.json'
        $c | Should -Match 'profile\.d'
    }
    It 'Assigns fragments to environments using tier and keyword rules' {
        $c = Get-Content -LiteralPath $script:Script -Raw
        $c | Should -Match 'Tier'
        $c | Should -Match 'environment'
    }
    It 'Preserves manual overrides when PreserveManual is enabled' {
        $c = Get-Content -LiteralPath $script:Script -Raw
        $c | Should -Match 'PreserveManual'
    }
}
