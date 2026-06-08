<#
tests/unit/profile-conversion-data-network-network-query-string-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/conversion-modules/data/network/network-query-string.ps1'
}
Describe 'profile.d/conversion-modules/data/network/network-query-string.ps1 extended scenarios' {
    It 'Documents Query string parsing and conversion utilities' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Query string parsing and conversion utilities'
        $c | Should -Match 'Ensure-FileConversion-Data'
    }
    It 'Defines Initialize-FileConversion-NetworkQueryString with core conversion helpers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Initialize-FileConversion-NetworkQueryString'
        $c | Should -Match 'Parse-QueryString'
    }
    It 'Registers parse-query and query-to-json entry points' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'parse-query'
        $c | Should -Match 'query-to-json'
    }
}
