<#
tests/unit/profile-dev-tools-uuid-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/dev-tools-modules/data/uuid.ps1'
}
Describe 'profile.d/dev-tools-modules/data/uuid.ps1 extended scenarios' {
    It 'Documents UUID generator utilities for multiple versions' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'UUID \(Universally Unique Identifier\) utilities'
        $c | Should -Match 'Ensure-DevTools'
    }
    It 'Defines Initialize-DevTools-Uuid with v1 and v4 generation' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Initialize-DevTools-Uuid'
        $c | Should -Match 'New-Uuid'
        $c | Should -Match 'New-UuidV5'
        $c | Should -Match 'NodeJs.psm1'
    }
    It 'Registers uuid, guid, and uuid-v5 aliases' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match "Set-AgentModeAlias -Name 'uuid'"
        $c | Should -Match "Set-AgentModeAlias -Name 'guid'"
        $c | Should -Match "Set-AgentModeAlias -Name 'uuid-v5'"
    }
}
