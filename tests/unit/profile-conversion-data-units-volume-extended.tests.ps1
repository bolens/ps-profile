<#
tests/unit/profile-conversion-data-units-volume-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/conversion-modules/data/units/volume.ps1'
}
Describe 'profile.d/conversion-modules/data/units/volume.ps1 extended scenarios' {
    It 'Documents Volume unit conversion utilities' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Volume unit conversion utilities'
        $c | Should -Match 'Ensure-FileConversion-Data'
    }
    It 'Defines Initialize-FileConversion-CoreUnitsVolume with core conversion helpers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Initialize-FileConversion-CoreUnitsVolume'
        $c | Should -Match '_Convert-Volume'
    }
    It 'Registers volume and liters-to-volume entry points' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'volume'
        $c | Should -Match 'liters-to-volume'
    }
}
