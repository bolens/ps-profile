<#
tests/unit/profile-conversion-data-encoding-modhex-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/conversion-modules/data/encoding/modhex.ps1'
}
Describe 'profile.d/conversion-modules/data/encoding/modhex.ps1 extended scenarios' {
    It 'Documents ModHex encoding conversion utilities' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'ModHex encoding conversion utilities'
        $c | Should -Match 'Initialize-FileConversion-CoreEncoding'
    }
    It 'Defines Initialize-FileConversion-CoreEncodingModHex with core conversion helpers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Initialize-FileConversion-CoreEncodingModHex'
        $c | Should -Match '_ConvertFrom-ModHexToAscii'
    }
    It 'Registers modhex-to-ascii and modhex-to-hex entry points' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'modhex-to-ascii'
        $c | Should -Match 'modhex-to-hex'
    }
}
