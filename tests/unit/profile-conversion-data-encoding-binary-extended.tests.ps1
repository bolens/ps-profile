<#
tests/unit/profile-conversion-data-encoding-binary-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/conversion-modules/data/encoding/binary.ps1'
}
Describe 'profile.d/conversion-modules/data/encoding/binary.ps1 extended scenarios' {
    It 'Documents Binary encoding conversion utilities' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Binary encoding conversion utilities'
        $c | Should -Match 'Initialize-FileConversion-CoreEncoding'
    }
    It 'Defines Initialize-FileConversion-CoreEncodingBinary with core conversion helpers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Initialize-FileConversion-CoreEncodingBinary'
        $c | Should -Match '_ConvertFrom-BinaryToAscii'
    }
    It 'Registers binary-to-ascii and binary-to-hex entry points' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'binary-to-ascii'
        $c | Should -Match 'binary-to-hex'
    }
}
