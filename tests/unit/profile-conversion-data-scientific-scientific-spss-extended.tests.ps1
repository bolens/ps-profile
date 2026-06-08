<#
tests/unit/profile-conversion-data-scientific-scientific-spss-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/conversion-modules/data/scientific/scientific-spss.ps1'
}
Describe 'profile.d/conversion-modules/data/scientific/scientific-spss.ps1 extended scenarios' {
    It 'Documents SPSS format conversion utilities' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'SPSS format conversion utilities'
        $c | Should -Match 'Ensure-FileConversion-Data'
    }
    It 'Defines Initialize-FileConversion-ScientificSpss with core conversion helpers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Initialize-FileConversion-ScientificSpss'
        $c | Should -Match 'Get-PythonPath'
    }
    It 'Registers spss-to-json and sav-to-json entry points' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'spss-to-json'
        $c | Should -Match 'sav-to-json'
    }
}
