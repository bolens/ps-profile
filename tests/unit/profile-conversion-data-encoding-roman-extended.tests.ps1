<#
tests/unit/profile-conversion-data-encoding-roman-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/conversion-modules/data/encoding/roman.ps1'
}
Describe 'profile.d/conversion-modules/data/encoding/roman.ps1 extended scenarios' {
    It 'Documents Roman numeral encoding conversion utilities' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Roman numeral encoding conversion utilities'
        $c | Should -Match 'Initialize-FileConversion-CoreEncoding'
    }
    It 'Defines Initialize-FileConversion-CoreEncodingRoman with core conversion helpers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Initialize-FileConversion-CoreEncodingRoman'
        $c | Should -Match '_ConvertFrom-RomanNumeral'
    }
    It 'Registers roman-to-ascii and roman-to-hex entry points' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'roman-to-ascii'
        $c | Should -Match 'roman-to-hex'
    }
}
