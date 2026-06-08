<#
tests/unit/profile-conversion-data-encoding-base36-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/conversion-modules/data/encoding/base36.ps1'
}
Describe 'profile.d/conversion-modules/data/encoding/base36.ps1 extended scenarios' {
    It 'Documents Base36 encoding conversion utilities' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Base36 encoding conversion utilities'
        $c | Should -Match 'Initialize-FileConversion-CoreEncoding'
    }
    It 'Defines Initialize-FileConversion-CoreEncodingBase36 with core conversion helpers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Initialize-FileConversion-CoreEncodingBase36'
        $c | Should -Match '_ConvertFrom-AsciiToBase36'
    }
    It 'Registers ascii-to-base36 and base36-to-ascii entry points' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'ascii-to-base36'
        $c | Should -Match 'base36-to-ascii'
    }
}
