<#
tests/unit/profile-conversion-data-units-angle-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/conversion-modules/data/units/angle.ps1'
}
Describe 'profile.d/conversion-modules/data/units/angle.ps1 extended scenarios' {
    It 'Documents Angle unit conversion utilities' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Angle unit conversion utilities'
        $c | Should -Match 'Ensure-FileConversion-Data'
    }
    It 'Defines Initialize-FileConversion-CoreUnitsAngle with core conversion helpers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Initialize-FileConversion-CoreUnitsAngle'
        $c | Should -Match '_Convert-Angle'
    }
    It 'Registers angle and radians-to-angle entry points' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'angle'
        $c | Should -Match 'radians-to-angle'
    }
}
