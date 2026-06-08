<#
tests/unit/profile-conversion-data-encoding-uuid-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/conversion-modules/data/encoding/uuid.ps1'
}
Describe 'profile.d/conversion-modules/data/encoding/uuid.ps1 extended scenarios' {
    It 'Documents UUID (Universally Unique Identifier) format conversion utilities' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'UUID \(Universally Unique Identifier\) format conversion utilities'
        $c | Should -Match 'Initialize-FileConversion-CoreEncoding'
    }
    It 'Defines Initialize-FileConversion-CoreEncodingUuid with core conversion helpers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Initialize-FileConversion-CoreEncodingUuid'
        $c | Should -Match '_ConvertFrom-UuidToHex'
    }
    It 'Registers uuid-to-hex and hex-to-uuid entry points' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'uuid-to-hex'
        $c | Should -Match 'hex-to-uuid'
    }
}
