<#
tests/unit/profile-conversion-data-encoding-ascii-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/conversion-modules/data/encoding/ascii.ps1'
}
Describe 'profile.d/conversion-modules/data/encoding/ascii.ps1 extended scenarios' {
    It 'Documents ASCII encoding conversion utilities' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'ASCII encoding conversion utilities'
        $c | Should -Match 'Initialize-FileConversion-CoreEncoding'
    }
    It 'Defines Initialize-FileConversion-CoreEncodingAscii with core conversion helpers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Initialize-FileConversion-CoreEncodingAscii'
        $c | Should -Match '_ConvertFrom-AsciiToHex'
    }
    It 'Registers ascii-to-hex and ascii-to-binary entry points' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'ascii-to-hex'
        $c | Should -Match 'ascii-to-binary'
    }
}
