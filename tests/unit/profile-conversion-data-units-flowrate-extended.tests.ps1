<#
tests/unit/profile-conversion-data-units-flowrate-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/conversion-modules/data/units/flowrate.ps1'
}
Describe 'profile.d/conversion-modules/data/units/flowrate.ps1 extended scenarios' {
    It 'Documents Flow rate unit conversion utilities' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Flow rate unit conversion utilities'
        $c | Should -Match 'Ensure-FileConversion-Data'
    }
    It 'Defines Initialize-FileConversion-CoreUnitsFlowRate with core conversion helpers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Initialize-FileConversion-CoreUnitsFlowRate'
        $c | Should -Match '_Convert-FlowRate'
    }
    It 'Registers flowrate and l-s-to-flowrate entry points' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'flowrate'
        $c | Should -Match 'l-s-to-flowrate'
    }
}
