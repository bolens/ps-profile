<#
tests/unit/profile-conversion-data-scientific-scientific-sas-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/conversion-modules/data/scientific/scientific-sas.ps1'
}
Describe 'profile.d/conversion-modules/data/scientific/scientific-sas.ps1 extended scenarios' {
    It 'Documents SAS format conversion utilities' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'SAS format conversion utilities'
        $c | Should -Match 'Ensure-FileConversion-Data'
    }
    It 'Defines Initialize-FileConversion-ScientificSas with core conversion helpers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Initialize-FileConversion-ScientificSas'
        $c | Should -Match 'Get-PythonPath'
    }
    It 'Registers sas-to-json and json-to-sas entry points' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'sas-to-json'
        $c | Should -Match 'json-to-sas'
    }
}
