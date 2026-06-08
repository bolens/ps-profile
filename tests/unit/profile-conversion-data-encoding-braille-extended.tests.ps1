<#
tests/unit/profile-conversion-data-encoding-braille-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/conversion-modules/data/encoding/braille.ps1'
}
Describe 'profile.d/conversion-modules/data/encoding/braille.ps1 extended scenarios' {
    It 'Documents Braille encoding conversion utilities' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Braille encoding conversion utilities'
        $c | Should -Match 'Initialize-FileConversion-CoreEncoding'
    }
    It 'Defines Initialize-FileConversion-CoreEncodingBraille with core conversion helpers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Initialize-FileConversion-CoreEncodingBraille'
        $c | Should -Match '_ConvertFrom-AsciiToBraille'
    }
    It 'Registers ascii-to-braille and braille-to-ascii entry points' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'ascii-to-braille'
        $c | Should -Match 'braille-to-ascii'
    }
}
