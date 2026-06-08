<#
tests/unit/profile-conversion-data-encoding-guid-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/conversion-modules/data/encoding/guid.ps1'
}
Describe 'profile.d/conversion-modules/data/encoding/guid.ps1 extended scenarios' {
    It 'Documents GUID (Globally Unique Identifier) format conversion utilities' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'GUID \(Globally Unique Identifier\) format conversion utilities'
        $c | Should -Match 'Initialize-FileConversion-CoreEncoding'
    }
    It 'Defines Initialize-FileConversion-CoreEncodingGuid with core conversion helpers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Initialize-FileConversion-CoreEncodingGuid'
        $c | Should -Match '_ConvertFrom-GuidToHex'
    }
    It 'Registers guid-to-hex and hex-to-guid entry points' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'guid-to-hex'
        $c | Should -Match 'hex-to-guid'
    }
}
