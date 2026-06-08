<#
tests/unit/profile-conversion-data-scientific-scientific-hdf5-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/conversion-modules/data/scientific/scientific-hdf5.ps1'
}
Describe 'profile.d/conversion-modules/data/scientific/scientific-hdf5.ps1 extended scenarios' {
    It 'Documents HDF5 format conversion utilities' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'HDF5 format conversion utilities'
        $c | Should -Match 'Ensure-FileConversion-Data'
    }
    It 'Defines Initialize-FileConversion-ScientificHdf5 with core conversion helpers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Initialize-FileConversion-ScientificHdf5'
        $c | Should -Match 'Get-PythonPath'
    }
    It 'Registers json-to-hdf5 and hdf5-to-json entry points' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'json-to-hdf5'
        $c | Should -Match 'hdf5-to-json'
    }
}
