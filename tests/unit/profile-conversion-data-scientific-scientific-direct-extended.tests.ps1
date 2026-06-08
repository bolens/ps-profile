<#
tests/unit/profile-conversion-data-scientific-scientific-direct-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/conversion-modules/data/scientific/scientific-direct.ps1'
}
Describe 'profile.d/conversion-modules/data/scientific/scientific-direct.ps1 extended scenarios' {
    It 'Documents Direct scientific format conversion utilities' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Direct scientific format conversion utilities'
        $c | Should -Match 'Ensure-FileConversion-Data'
    }
    It 'Defines Initialize-FileConversion-ScientificDirect with core conversion helpers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Initialize-FileConversion-ScientificDirect'
        $c | Should -Match 'Get-PythonPath'
    }
    It 'Registers hdf5-to-netcdf and netcdf-to-hdf5 entry points' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'hdf5-to-netcdf'
        $c | Should -Match 'netcdf-to-hdf5'
    }
}
