<#
tests/unit/profile-conversion-data-encoding-base32-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/conversion-modules/data/encoding/base32.ps1'
}
Describe 'profile.d/conversion-modules/data/encoding/base32.ps1 extended scenarios' {
    It 'Documents Base32 encoding conversion utilities' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Base32 encoding conversion utilities'
        $c | Should -Match 'Initialize-FileConversion-CoreEncoding'
    }
    It 'Defines Initialize-FileConversion-CoreEncodingBase32 with core conversion helpers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Initialize-FileConversion-CoreEncodingBase32'
        $c | Should -Match '_ConvertFrom-Base32ToAscii'
    }
    It 'Registers base32-to-ascii and base32-to-hex entry points' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'base32-to-ascii'
        $c | Should -Match 'base32-to-hex'
    }
}
