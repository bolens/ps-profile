<#
tests/unit/profile-conversion-data-columnar-columnar-direct-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/conversion-modules/data/columnar/columnar-direct.ps1'
}
Describe 'profile.d/conversion-modules/data/columnar/columnar-direct.ps1 extended scenarios' {
    It 'Documents Direct columnar format conversion utilities' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Direct columnar format conversion utilities'
        $c | Should -Match 'Ensure-FileConversion-Data'
    }
    It 'Defines Initialize-FileConversion-ColumnarDirect with core conversion helpers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Initialize-FileConversion-ColumnarDirect'
        $c | Should -Match 'Test-CachedCommand ''node'''
    }
    It 'Registers parquet-to-arrow and arrow-to-parquet entry points' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'parquet-to-arrow'
        $c | Should -Match 'arrow-to-parquet'
    }
}
