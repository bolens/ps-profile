<#
tests/unit/profile-conversion-data-units-pressure-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/conversion-modules/data/units/pressure.ps1'
}
Describe 'profile.d/conversion-modules/data/units/pressure.ps1 extended scenarios' {
    It 'Documents Pressure unit conversion utilities' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Pressure unit conversion utilities'
        $c | Should -Match 'Ensure-FileConversion-Data'
    }
    It 'Defines Initialize-FileConversion-CoreUnitsPressure with core conversion helpers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Initialize-FileConversion-CoreUnitsPressure'
        $c | Should -Match '_Convert-Pressure'
    }
    It 'Registers pressure and pa-to-pressure entry points' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'pressure'
        $c | Should -Match 'pa-to-pressure'
    }
}
