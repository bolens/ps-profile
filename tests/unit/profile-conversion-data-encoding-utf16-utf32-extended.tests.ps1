<#
tests/unit/profile-conversion-data-encoding-utf16-utf32-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/conversion-modules/data/encoding/utf16-utf32.ps1'
}
Describe 'profile.d/conversion-modules/data/encoding/utf16-utf32.ps1 extended scenarios' {
    It 'Documents UTF-16/UTF-32 encoding conversion utilities' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'UTF-16/UTF-32 encoding conversion utilities'
        $c | Should -Match 'Initialize-FileConversion-CoreEncoding'
    }
    It 'Defines Initialize-FileConversion-CoreEncodingUtf16Utf32 with core conversion helpers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Initialize-FileConversion-CoreEncodingUtf16Utf32'
        $c | Should -Match '_Encode-Utf16'
    }
    It 'Registers ascii-to-utf16 and utf16-to-ascii entry points' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'ascii-to-utf16'
        $c | Should -Match 'utf16-to-ascii'
    }
}
