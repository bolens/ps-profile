<#
tests/unit/profile-conversion-data-structured-asn1-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/conversion-modules/data/structured/asn1.ps1'
}
Describe 'profile.d/conversion-modules/data/structured/asn1.ps1 extended scenarios' {
    It 'Documents ASN\.1 \(Abstract Syntax Notation One\) format conversion utilities' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'ASN\.1 \(Abstract Syntax Notation One\) format conversion utilities'
        $c | Should -Match 'Ensure-FileConversion-Data'
    }
    It 'Defines Initialize-FileConversion-Asn1 with core conversion helpers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Initialize-FileConversion-Asn1'
        $c | Should -Match '_ConvertFrom-Asn1ToJson'
    }
    It 'Registers asn1-to-json and json-to-asn1 entry points' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'asn1-to-json'
        $c | Should -Match 'json-to-asn1'
    }
}
