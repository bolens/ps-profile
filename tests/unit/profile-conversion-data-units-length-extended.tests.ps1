<#
tests/unit/profile-conversion-data-units-length-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/conversion-modules/data/units/length.ps1'
}
Describe 'profile.d/conversion-modules/data/units/length.ps1 extended scenarios' {
    It 'Documents Length unit conversion utilities' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Length unit conversion utilities'
        $c | Should -Match 'Ensure-FileConversion-Data'
    }
    It 'Defines Initialize-FileConversion-CoreUnitsLength with core conversion helpers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Initialize-FileConversion-CoreUnitsLength'
        $c | Should -Match '_Convert-Length'
    }
    It 'Registers length and meters-to-length entry points' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'length'
        $c | Should -Match 'meters-to-length'
    }
}
