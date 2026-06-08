<#
tests/unit/profile-conversion-data-encoding-base91-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/conversion-modules/data/encoding/base91.ps1'
}
Describe 'profile.d/conversion-modules/data/encoding/base91.ps1 extended scenarios' {
    It 'Documents Base91 encoding conversion utilities' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Base91 encoding conversion utilities'
        $c | Should -Match 'Initialize-FileConversion-CoreEncoding'
    }
    It 'Defines Initialize-FileConversion-CoreEncodingBase91 with core conversion helpers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Initialize-FileConversion-CoreEncodingBase91'
        $c | Should -Match '_ConvertFrom-AsciiToBase91'
    }
    It 'Registers ascii-to-base91 and base91-to-ascii entry points' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'ascii-to-base91'
        $c | Should -Match 'base91-to-ascii'
    }
}
