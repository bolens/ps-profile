<#
tests/unit/profile-conversion-data-core-text-gaps-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/conversion-modules/data/core/text-gaps.ps1'
}
Describe 'profile.d/conversion-modules/data/core/text-gaps.ps1 extended scenarios' {
    It 'Documents Text format gap conversion utilities' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Text format gap conversion utilities'
        $c | Should -Match 'Ensure-FileConversion-Data'
    }
    It 'Defines Initialize-FileConversion-CoreTextGaps with core conversion helpers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Initialize-FileConversion-CoreTextGaps'
        $c | Should -Match '_ConvertFrom-JsonLToCsv'
    }
    It 'Registers jsonl-to-csv and yaml-to-jsonl aliases' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Set-AgentModeAlias -Name ''jsonl-to-csv'''
        $c | Should -Match 'Set-AgentModeAlias -Name ''yaml-to-jsonl'''
    }
}
