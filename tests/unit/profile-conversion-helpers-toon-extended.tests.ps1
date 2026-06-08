<#
tests/unit/profile-conversion-helpers-toon-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/conversion-modules/helpers/helpers-toon.ps1'
}
Describe 'profile.d/conversion-modules/helpers/helpers-toon.ps1 extended scenarios' {
    It 'Documents TOON conversion helpers for AI token efficiency' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Token-Oriented Object Notation'
        $c | Should -Match 'JSON ↔ TOON conversion helpers'
    }
    It 'Defines Convert-JsonToToon and Convert-ToonToJson conversion functions' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Convert-JsonToToon'
        $c | Should -Match 'Convert-ToonToJson'
        $c | Should -Match 'Parse-ToonLines'
    }
    It 'Uses compact TOON array syntax without JSON brackets' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'no brackets'
        $c | Should -Match 'Parse-ToonValue'
        $c | Should -Match 'reduce token usage'
    }
}
