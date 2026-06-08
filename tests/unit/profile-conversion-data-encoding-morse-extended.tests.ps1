<#
tests/unit/profile-conversion-data-encoding-morse-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/conversion-modules/data/encoding/morse.ps1'
}
Describe 'profile.d/conversion-modules/data/encoding/morse.ps1 extended scenarios' {
    It 'Documents Morse Code encoding conversion utilities' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Morse Code encoding conversion utilities'
        $c | Should -Match 'Initialize-FileConversion-CoreEncoding'
    }
    It 'Defines Initialize-FileConversion-CoreEncodingMorse with core conversion helpers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Initialize-FileConversion-CoreEncodingMorse'
        $c | Should -Match '_ConvertFrom-AsciiToMorse'
    }
    It 'Registers ascii-to-morse and morse-to-ascii entry points' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'ascii-to-morse'
        $c | Should -Match 'morse-to-ascii'
    }
}
