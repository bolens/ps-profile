<#
tests/unit/profile-conversion-data-units-time-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/conversion-modules/data/units/time.ps1'
}
Describe 'profile.d/conversion-modules/data/units/time.ps1 extended scenarios' {
    It 'Documents Time duration unit conversion utilities' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Time duration unit conversion utilities'
        $c | Should -Match 'Ensure-FileConversion-Data'
    }
    It 'Defines Initialize-FileConversion-CoreUnitsTime with core conversion helpers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Initialize-FileConversion-CoreUnitsTime'
        $c | Should -Match '_Convert-Duration'
    }
    It 'Registers duration-units and seconds-to-time entry points' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'duration-units'
        $c | Should -Match 'seconds-to-time'
    }
}
