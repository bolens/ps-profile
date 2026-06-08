<#
tests/unit/profile-conversion-data-scientific-scientific-stata-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/conversion-modules/data/scientific/scientific-stata.ps1'
}
Describe 'profile.d/conversion-modules/data/scientific/scientific-stata.ps1 extended scenarios' {
    It 'Documents Stata format conversion utilities' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Stata format conversion utilities'
        $c | Should -Match 'Ensure-FileConversion-Data'
    }
    It 'Defines Initialize-FileConversion-ScientificStata with core conversion helpers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Initialize-FileConversion-ScientificStata'
        $c | Should -Match 'Get-PythonPath'
    }
    It 'Registers stata-to-json and dta-to-json entry points' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'stata-to-json'
        $c | Should -Match 'dta-to-json'
    }
}
