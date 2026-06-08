<#
tests/unit/profile-conversion-data-structured-edifact-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/conversion-modules/data/structured/edifact.ps1'
}
Describe 'profile.d/conversion-modules/data/structured/edifact.ps1 extended scenarios' {
    It 'Documents EDIFACT \(Electronic Data Interchange\) format conversion utilities' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'EDIFACT \(Electronic Data Interchange\) format conversion utilities'
        $c | Should -Match 'Ensure-FileConversion-Data'
    }
    It 'Defines Initialize-FileConversion-Edifact with core conversion helpers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Initialize-FileConversion-Edifact'
        $c | Should -Match '_ConvertFrom-EdifactToJson'
    }
    It 'Registers edifact-to-json and json-to-edifact entry points' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'edifact-to-json'
        $c | Should -Match 'json-to-edifact'
    }
}
