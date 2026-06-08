<#
tests/unit/profile-conversion-data-structured-hjson-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/conversion-modules/data/structured/hjson.ps1'
}
Describe 'profile.d/conversion-modules/data/structured/hjson.ps1 extended scenarios' {
    It 'Documents HJSON \(Human JSON\) format conversion utilities' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'HJSON \(Human JSON\) format conversion utilities'
        $c | Should -Match 'Ensure-FileConversion-Data'
    }
    It 'Defines Initialize-FileConversion-Hjson with core conversion helpers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Initialize-FileConversion-Hjson'
        $c | Should -Match '_ConvertFrom-HjsonToJson'
    }
    It 'Registers hjson-to-json and json-to-hjson entry points' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'hjson-to-json'
        $c | Should -Match 'json-to-hjson'
    }
}
