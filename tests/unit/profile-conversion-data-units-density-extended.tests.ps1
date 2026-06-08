<#
tests/unit/profile-conversion-data-units-density-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/conversion-modules/data/units/density.ps1'
}
Describe 'profile.d/conversion-modules/data/units/density.ps1 extended scenarios' {
    It 'Documents Density unit conversion utilities' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Density unit conversion utilities'
        $c | Should -Match 'Ensure-FileConversion-Data'
    }
    It 'Defines Initialize-FileConversion-CoreUnitsDensity with core conversion helpers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Initialize-FileConversion-CoreUnitsDensity'
        $c | Should -Match '_Convert-Density'
    }
    It 'Registers density and kg-m3-to-density entry points' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'density'
        $c | Should -Match 'kg-m3-to-density'
    }
}
