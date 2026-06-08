<#
tests/unit/profile-conversion-data-scientific-scientific-to-columnar-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/conversion-modules/data/scientific/scientific-to-columnar.ps1'
}
Describe 'profile.d/conversion-modules/data/scientific/scientific-to-columnar.ps1 extended scenarios' {
    It 'Documents Scientific to columnar format conversion utilities' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Scientific to columnar format conversion utilities'
        $c | Should -Match 'Ensure-FileConversion-Data'
    }
    It 'Defines Initialize-FileConversion-ScientificToColumnar with core conversion helpers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Initialize-FileConversion-ScientificToColumnar'
        $c | Should -Match 'Test-CachedCommand ''node'''
    }
    It 'Registers hdf5-to-parquet and netcdf-to-parquet entry points' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'hdf5-to-parquet'
        $c | Should -Match 'netcdf-to-parquet'
    }
}
