<#
tests/unit/profile-conversion-data-units-speed-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/conversion-modules/data/units/speed.ps1'
}
Describe 'profile.d/conversion-modules/data/units/speed.ps1 extended scenarios' {
    It 'Documents Speed unit conversion utilities' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Speed unit conversion utilities'
        $c | Should -Match 'Ensure-FileConversion-Data'
    }
    It 'Defines Initialize-FileConversion-CoreUnitsSpeed with core conversion helpers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Initialize-FileConversion-CoreUnitsSpeed'
        $c | Should -Match '_Convert-Speed'
    }
    It 'Registers speed and mps-to-speed entry points' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'speed'
        $c | Should -Match 'mps-to-speed'
    }
}
