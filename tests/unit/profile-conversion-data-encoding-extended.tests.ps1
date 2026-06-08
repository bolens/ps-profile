<#
tests/unit/profile-conversion-data-encoding-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/conversion-modules/data/encoding/encoding.ps1'
}
Describe 'profile.d/conversion-modules/data/encoding/encoding.ps1 extended scenarios' {
    It 'Documents Encoding conversion utilities' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Encoding conversion utilities'
        $c | Should -Match 'Ensure-FileConversion-Data'
    }
    It 'Defines Initialize-FileConversion-CoreEncoding with core conversion helpers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Initialize-FileConversion-CoreEncoding'
        $c | Should -Match 'ascii.ps1'
    }
    It 'Registers Initialize-FileConversion-CoreEncodingAscii and Initialize-FileConversion-CoreEncodingHex entry points' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Initialize-FileConversion-CoreEncodingAscii'
        $c | Should -Match 'Initialize-FileConversion-CoreEncodingHex'
    }
}
