<#
tests/unit/profile-conversion-data-units-datarate-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/conversion-modules/data/units/datarate.ps1'
}
Describe 'profile.d/conversion-modules/data/units/datarate.ps1 extended scenarios' {
    It 'Documents Data rate unit conversion utilities' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Data rate unit conversion utilities'
        $c | Should -Match 'Ensure-FileConversion-Data'
    }
    It 'Defines Initialize-FileConversion-CoreUnitsDataRate with core conversion helpers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Initialize-FileConversion-CoreUnitsDataRate'
        $c | Should -Match '_Convert-DataRate'
    }
    It 'Registers datarate and bps-to-datarate entry points' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'datarate'
        $c | Should -Match 'bps-to-datarate'
    }
}
