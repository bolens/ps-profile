<#
tests/unit/profile-conversion-data-units-temperature-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/conversion-modules/data/units/temperature.ps1'
}
Describe 'profile.d/conversion-modules/data/units/temperature.ps1 extended scenarios' {
    It 'Documents Temperature unit conversion utilities' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Temperature unit conversion utilities'
        $c | Should -Match 'Ensure-FileConversion-Data'
    }
    It 'Defines Initialize-FileConversion-CoreUnitsTemperature with core conversion helpers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Initialize-FileConversion-CoreUnitsTemperature'
        $c | Should -Match '_Convert-Temperature'
    }
    It 'Registers temp and celsius-to-temp entry points' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'temp'
        $c | Should -Match 'celsius-to-temp'
    }
}
