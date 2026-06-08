<#
tests/unit/profile-conversion-data-columnar-columnar-arrow-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/conversion-modules/data/columnar/columnar-arrow.ps1'
}
Describe 'profile.d/conversion-modules/data/columnar/columnar-arrow.ps1 extended scenarios' {
    It 'Documents Arrow format conversion utilities' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Arrow format conversion utilities'
        $c | Should -Match 'Ensure-FileConversion-Data'
    }
    It 'Defines Initialize-FileConversion-ColumnarArrow with core conversion helpers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Initialize-FileConversion-ColumnarArrow'
        $c | Should -Match 'Test-CachedCommand ''node'''
    }
    It 'Registers json-to-arrow and arrow-to-json entry points' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'json-to-arrow'
        $c | Should -Match 'arrow-to-json'
    }
}
