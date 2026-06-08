<#
tests/unit/profile-conversion-data-network-network-http-headers-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/conversion-modules/data/network/network-http-headers.ps1'
}
Describe 'profile.d/conversion-modules/data/network/network-http-headers.ps1 extended scenarios' {
    It 'Documents HTTP headers parsing and conversion utilities' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'HTTP headers parsing and conversion utilities'
        $c | Should -Match 'Ensure-FileConversion-Data'
    }
    It 'Defines Initialize-FileConversion-NetworkHttpHeaders with core conversion helpers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Initialize-FileConversion-NetworkHttpHeaders'
        $c | Should -Match '_Parse-HttpHeaders'
    }
    It 'Registers parse-headers and headers-to-json entry points' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'parse-headers'
        $c | Should -Match 'headers-to-json'
    }
}
