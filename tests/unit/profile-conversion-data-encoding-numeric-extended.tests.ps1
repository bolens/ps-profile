<#
tests/unit/profile-conversion-data-encoding-numeric-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/conversion-modules/data/encoding/numeric.ps1'
}
Describe 'profile.d/conversion-modules/data/encoding/numeric.ps1 extended scenarios' {
    It 'Documents Numeric encoding conversion utilities (Octal and Decimal)' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Numeric encoding conversion utilities \(Octal and Decimal\)'
        $c | Should -Match 'Initialize-FileConversion-CoreEncoding'
    }
    It 'Defines Initialize-FileConversion-CoreEncodingNumeric with core conversion helpers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Initialize-FileConversion-CoreEncodingNumeric'
        $c | Should -Match '_ConvertFrom-OctalToAscii'
    }
    It 'Registers octal-to-ascii and decimal-to-ascii entry points' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'octal-to-ascii'
        $c | Should -Match 'decimal-to-ascii'
    }
}
