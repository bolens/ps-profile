<#
tests/unit/profile-conversion-data-units-typography-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/conversion-modules/data/units/typography.ps1'
}
Describe 'profile.d/conversion-modules/data/units/typography.ps1 extended scenarios' {
    It 'Documents Typography unit conversion utilities' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Typography unit conversion utilities'
        $c | Should -Match 'Ensure-FileConversion-Data'
    }
    It 'Defines Initialize-FileConversion-CoreUnitsTypography with core conversion helpers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Initialize-FileConversion-CoreUnitsTypography'
        $c | Should -Match '_Convert-Typography'
    }
    It 'Registers typography and meters-to-typography entry points' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'typography'
        $c | Should -Match 'meters-to-typography'
    }
}
