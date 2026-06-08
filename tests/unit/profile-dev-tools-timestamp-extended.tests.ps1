<#
tests/unit/profile-dev-tools-timestamp-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/dev-tools-modules/data/timestamp.ps1'
}
Describe 'profile.d/dev-tools-modules/data/timestamp.ps1 extended scenarios' {
    It 'Documents timestamp conversion utilities for Unix epoch' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Timestamp conversion utilities'
        $c | Should -Match 'Unix epoch'
    }
    It 'Defines ConvertFrom-Epoch and ConvertTo-Epoch with millisecond support' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'ConvertFrom-Epoch'
        $c | Should -Match 'ConvertTo-Epoch'
        $c | Should -Match 'Initialize-DevTools-Timestamp'
    }
    It 'Registers epoch-to-date and date-to-epoch aliases' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match "Set-AgentModeAlias -Name 'epoch-to-date'"
        $c | Should -Match "Set-AgentModeAlias -Name 'date-to-epoch'"
    }
}
