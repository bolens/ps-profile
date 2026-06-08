<#
tests/unit/profile-conversion-data-units-weight-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/conversion-modules/data/units/weight.ps1'
}
Describe 'profile.d/conversion-modules/data/units/weight.ps1 extended scenarios' {
    It 'Documents Weight/Mass unit conversion utilities' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Weight/Mass unit conversion utilities'
        $c | Should -Match 'Ensure-FileConversion-Data'
    }
    It 'Defines Initialize-FileConversion-CoreUnitsWeight with core conversion helpers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Initialize-FileConversion-CoreUnitsWeight'
        $c | Should -Match '_Convert-Weight'
    }
    It 'Registers weight and kg-to-weight entry points' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'weight'
        $c | Should -Match 'kg-to-weight'
    }
}
