<#
tests/unit/profile-conversion-data-encoding-z85-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/conversion-modules/data/encoding/z85.ps1'
}
Describe 'profile.d/conversion-modules/data/encoding/z85.ps1 extended scenarios' {
    It 'Documents Z85 encoding conversion utilities' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Z85 encoding conversion utilities'
        $c | Should -Match 'Initialize-FileConversion-CoreEncoding'
    }
    It 'Defines Initialize-FileConversion-CoreEncodingZ85 with core conversion helpers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Initialize-FileConversion-CoreEncodingZ85'
        $c | Should -Match '_Encode-Z85'
    }
    It 'Registers ascii-to-z85 and z85-to-ascii entry points' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'ascii-to-z85'
        $c | Should -Match 'z85-to-ascii'
    }
}
