<#
tests/unit/profile-conversion-data-encoding-base122-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/conversion-modules/data/encoding/base122.ps1'
}
Describe 'profile.d/conversion-modules/data/encoding/base122.ps1 extended scenarios' {
    It 'Documents Base122 encoding conversion utilities' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Base122 encoding conversion utilities'
        $c | Should -Match 'Initialize-FileConversion-CoreEncoding'
    }
    It 'Defines Initialize-FileConversion-CoreEncodingBase122 with core conversion helpers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Initialize-FileConversion-CoreEncodingBase122'
        $c | Should -Match '_ConvertFrom-AsciiToBase122'
    }
    It 'Registers ascii-to-base122 and base122-to-ascii entry points' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'ascii-to-base122'
        $c | Should -Match 'base122-to-ascii'
    }
}
