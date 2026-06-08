<#
tests/unit/profile-conversion-data-encoding-base62-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/conversion-modules/data/encoding/base62.ps1'
}
Describe 'profile.d/conversion-modules/data/encoding/base62.ps1 extended scenarios' {
    It 'Documents Base62 encoding conversion utilities' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Base62 encoding conversion utilities'
        $c | Should -Match 'Initialize-FileConversion-CoreEncoding'
    }
    It 'Defines Initialize-FileConversion-CoreEncodingBase62 with core conversion helpers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Initialize-FileConversion-CoreEncodingBase62'
        $c | Should -Match '_ConvertFrom-AsciiToBase62'
    }
    It 'Registers ascii-to-base62 and base62-to-ascii entry points' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'ascii-to-base62'
        $c | Should -Match 'base62-to-ascii'
    }
}
