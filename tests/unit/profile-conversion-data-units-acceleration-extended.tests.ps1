<#
tests/unit/profile-conversion-data-units-acceleration-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/conversion-modules/data/units/acceleration.ps1'
}
Describe 'profile.d/conversion-modules/data/units/acceleration.ps1 extended scenarios' {
    It 'Documents Acceleration unit conversion utilities' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Acceleration unit conversion utilities'
        $c | Should -Match 'Ensure-FileConversion-Data'
    }
    It 'Defines Initialize-FileConversion-CoreUnitsAcceleration with core conversion helpers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Initialize-FileConversion-CoreUnitsAcceleration'
        $c | Should -Match '_Convert-Acceleration'
    }
    It 'Registers acceleration and m-s2-to-acceleration entry points' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'acceleration'
        $c | Should -Match 'm-s2-to-acceleration'
    }
}
