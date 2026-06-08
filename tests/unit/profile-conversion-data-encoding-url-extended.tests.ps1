<#
tests/unit/profile-conversion-data-encoding-url-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/conversion-modules/data/encoding/url.ps1'
}
Describe 'profile.d/conversion-modules/data/encoding/url.ps1 extended scenarios' {
    It 'Documents URL/Percent encoding conversion utilities' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'URL/Percent encoding conversion utilities'
        $c | Should -Match 'Initialize-FileConversion-CoreEncoding'
    }
    It 'Defines Initialize-FileConversion-CoreEncodingUrl with core conversion helpers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Initialize-FileConversion-CoreEncodingUrl'
        $c | Should -Match '_ConvertFrom-UrlToAscii'
    }
    It 'Registers url-encode and url-decode entry points' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'url-encode'
        $c | Should -Match 'url-decode'
    }
}
