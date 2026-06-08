<#
tests/unit/profile-conversion-data-structured-ion-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/conversion-modules/data/structured/ion.ps1'
}
Describe 'profile.d/conversion-modules/data/structured/ion.ps1 extended scenarios' {
    It 'Documents Ion \(Amazon Ion\) format conversion utilities' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Ion \(Amazon Ion\) format conversion utilities'
        $c | Should -Match 'Ensure-FileConversion-Data'
    }
    It 'Defines Initialize-FileConversion-Ion with core conversion helpers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Initialize-FileConversion-Ion'
        $c | Should -Match 'Get-PythonPath'
    }
    It 'Registers ion-to-json and json-to-ion entry points' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'ion-to-json'
        $c | Should -Match 'json-to-ion'
    }
}
