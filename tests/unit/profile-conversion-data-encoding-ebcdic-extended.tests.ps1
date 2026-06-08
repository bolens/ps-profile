<#
tests/unit/profile-conversion-data-encoding-ebcdic-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/conversion-modules/data/encoding/ebcdic.ps1'
}
Describe 'profile.d/conversion-modules/data/encoding/ebcdic.ps1 extended scenarios' {
    It 'Documents EBCDIC encoding conversion utilities' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'EBCDIC encoding conversion utilities'
        $c | Should -Match 'Initialize-FileConversion-CoreEncoding'
    }
    It 'Defines Initialize-FileConversion-CoreEncodingEBCDIC with core conversion helpers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Initialize-FileConversion-CoreEncodingEBCDIC'
        $c | Should -Match '_ConvertFrom-AsciiToEBCDIC'
    }
    It 'Registers ascii-to-ebcdic and ebcdic-to-ascii entry points' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'ascii-to-ebcdic'
        $c | Should -Match 'ebcdic-to-ascii'
    }
}
