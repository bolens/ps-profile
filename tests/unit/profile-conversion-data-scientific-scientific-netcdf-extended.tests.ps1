<#
tests/unit/profile-conversion-data-scientific-scientific-netcdf-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/conversion-modules/data/scientific/scientific-netcdf.ps1'
}
Describe 'profile.d/conversion-modules/data/scientific/scientific-netcdf.ps1 extended scenarios' {
    It 'Documents NetCDF format conversion utilities' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'NetCDF format conversion utilities'
        $c | Should -Match 'Ensure-FileConversion-Data'
    }
    It 'Defines Initialize-FileConversion-ScientificNetCdf with core conversion helpers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Initialize-FileConversion-ScientificNetCdf'
        $c | Should -Match 'Get-PythonPath'
    }
    It 'Registers json-to-netcdf and netcdf-to-json entry points' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'json-to-netcdf'
        $c | Should -Match 'netcdf-to-json'
    }
}
