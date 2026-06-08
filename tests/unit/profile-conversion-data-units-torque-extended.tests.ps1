<#
tests/unit/profile-conversion-data-units-torque-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/conversion-modules/data/units/torque.ps1'
}
Describe 'profile.d/conversion-modules/data/units/torque.ps1 extended scenarios' {
    It 'Documents Torque unit conversion utilities' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Torque unit conversion utilities'
        $c | Should -Match 'Ensure-FileConversion-Data'
    }
    It 'Defines Initialize-FileConversion-CoreUnitsTorque with core conversion helpers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Initialize-FileConversion-CoreUnitsTorque'
        $c | Should -Match '_Convert-Torque'
    }
    It 'Registers torque and nm-to-torque entry points' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'torque'
        $c | Should -Match 'nm-to-torque'
    }
}
