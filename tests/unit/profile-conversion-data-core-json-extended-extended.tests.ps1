<#
tests/unit/profile-conversion-data-core-json-extended-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/conversion-modules/data/core/json-extended.ps1'
}
Describe 'profile.d/conversion-modules/data/core/json-extended.ps1 extended scenarios' {
    It 'Documents Extended JSON format conversion utilities' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Extended JSON format conversion utilities'
        $c | Should -Match 'Ensure-FileConversion-Data'
    }
    It 'Defines Initialize-FileConversion-CoreJsonExtended with core conversion helpers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Initialize-FileConversion-CoreJsonExtended'
        $c | Should -Match 'Test-CachedCommand ''node'''
    }
    It 'Registers json5-to-json and jsonl-to-json entry points' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'json5-to-json'
        $c | Should -Match 'jsonl-to-json'
    }
}
