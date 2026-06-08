<#
tests/unit/profile-conversion-data-encoding-base85-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/conversion-modules/data/encoding/base85.ps1'
}
Describe 'profile.d/conversion-modules/data/encoding/base85.ps1 extended scenarios' {
    It 'Documents Base85/Ascii85 encoding conversion utilities' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Base85/Ascii85 encoding conversion utilities'
        $c | Should -Match 'Initialize-FileConversion-CoreEncoding'
    }
    It 'Defines Initialize-FileConversion-CoreEncodingBase85 with core conversion helpers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Initialize-FileConversion-CoreEncodingBase85'
        $c | Should -Match '_ConvertFrom-AsciiToBase85'
    }
    It 'Registers ascii-to-base85 and base85-to-ascii entry points' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'ascii-to-base85'
        $c | Should -Match 'base85-to-ascii'
    }
}
