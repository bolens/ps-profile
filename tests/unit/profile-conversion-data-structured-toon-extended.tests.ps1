<#
tests/unit/profile-conversion-data-structured-toon-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/conversion-modules/data/structured/toon.ps1'
}
Describe 'profile.d/conversion-modules/data/structured/toon.ps1 extended scenarios' {
    It 'Documents TOON \(Token-Oriented Object Notation\) conversion utilities' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'TOON \(Token-Oriented Object Notation\) conversion utilities'
        $c | Should -Match 'Ensure-FileConversion-Data'
    }
    It 'Defines Initialize-FileConversion-Toon with core conversion helpers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Initialize-FileConversion-Toon'
        $c | Should -Match '_ConvertTo-ToonFromJson'
    }
    It 'Registers json-to-toon and toon-to-json entry points' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'json-to-toon'
        $c | Should -Match 'toon-to-json'
    }
}
