<#
tests/unit/profile-conversion-data-units-fueleconomy-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/conversion-modules/data/units/fueleconomy.ps1'
}
Describe 'profile.d/conversion-modules/data/units/fueleconomy.ps1 extended scenarios' {
    It 'Documents Fuel economy unit conversion utilities' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Fuel economy unit conversion utilities'
        $c | Should -Match 'Ensure-FileConversion-Data'
    }
    It 'Defines Initialize-FileConversion-CoreUnitsFuelEconomy with core conversion helpers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Initialize-FileConversion-CoreUnitsFuelEconomy'
        $c | Should -Match '_Convert-FuelEconomy'
    }
    It 'Registers fueleconomy and mpgus entry points' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'fueleconomy'
        $c | Should -Match 'mpgus'
    }
}
