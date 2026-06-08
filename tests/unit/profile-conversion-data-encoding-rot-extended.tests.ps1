<#
tests/unit/profile-conversion-data-encoding-rot-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/conversion-modules/data/encoding/rot.ps1'
}
Describe 'profile.d/conversion-modules/data/encoding/rot.ps1 extended scenarios' {
    It 'Documents ROT13/ROT47 cipher encoding conversion utilities' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'ROT13/ROT47 cipher encoding conversion utilities'
        $c | Should -Match 'Initialize-FileConversion-CoreEncoding'
    }
    It 'Defines Initialize-FileConversion-CoreEncodingRot with core conversion helpers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Initialize-FileConversion-CoreEncodingRot'
        $c | Should -Match '_ConvertFrom-AsciiToRot13'
    }
    It 'Registers ascii-to-rot13 and rot13 entry points' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'ascii-to-rot13'
        $c | Should -Match 'rot13'
    }
}
