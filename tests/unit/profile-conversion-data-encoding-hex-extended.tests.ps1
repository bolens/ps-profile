<#
tests/unit/profile-conversion-data-encoding-hex-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/conversion-modules/data/encoding/hex.ps1'
}
Describe 'profile.d/conversion-modules/data/encoding/hex.ps1 extended scenarios' {
    It 'Documents Hexadecimal encoding conversion utilities' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Hexadecimal encoding conversion utilities'
        $c | Should -Match 'Initialize-FileConversion-CoreEncoding'
    }
    It 'Defines Initialize-FileConversion-CoreEncodingHex with core conversion helpers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Initialize-FileConversion-CoreEncodingHex'
        $c | Should -Match '_ConvertFrom-HexToAscii'
    }
    It 'Registers hex-to-ascii and hex-to-binary entry points' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'hex-to-ascii'
        $c | Should -Match 'hex-to-binary'
    }
}
