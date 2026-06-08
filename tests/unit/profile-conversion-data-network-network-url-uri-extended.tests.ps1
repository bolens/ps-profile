<#
tests/unit/profile-conversion-data-network-network-url-uri-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/conversion-modules/data/network/network-url-uri.ps1'
}
Describe 'profile.d/conversion-modules/data/network/network-url-uri.ps1 extended scenarios' {
    It 'Documents URL/URI parsing and conversion utilities' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'URL/URI parsing and conversion utilities'
        $c | Should -Match 'Ensure-FileConversion-Data'
    }
    It 'Defines Initialize-FileConversion-NetworkUrlUri with core conversion helpers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Initialize-FileConversion-NetworkUrlUri'
        $c | Should -Match '_Parse-UrlUri'
    }
    It 'Registers parse-url and url-to-json entry points' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'parse-url'
        $c | Should -Match 'url-to-json'
    }
}
