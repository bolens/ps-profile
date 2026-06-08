<#
tests/unit/profile-conversion-data-units-frequency-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/conversion-modules/data/units/frequency.ps1'
}
Describe 'profile.d/conversion-modules/data/units/frequency.ps1 extended scenarios' {
    It 'Documents Frequency unit conversion utilities' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Frequency unit conversion utilities'
        $c | Should -Match 'Ensure-FileConversion-Data'
    }
    It 'Defines Initialize-FileConversion-CoreUnitsFrequency with core conversion helpers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Initialize-FileConversion-CoreUnitsFrequency'
        $c | Should -Match '_Convert-Frequency'
    }
    It 'Registers frequency and hz-to-frequency entry points' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'frequency'
        $c | Should -Match 'hz-to-frequency'
    }
}
