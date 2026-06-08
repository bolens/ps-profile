<#
tests/unit/profile-conversion-data-binary-binary-schema-avro-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/conversion-modules/data/binary/binary-schema-avro.ps1'
}
Describe 'profile.d/conversion-modules/data/binary/binary-schema-avro.ps1 extended scenarios' {
    It 'Documents Avro schema conversion utilities' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Avro schema conversion utilities'
        $c | Should -Match 'Ensure-FileConversion-Data'
    }
    It 'Defines Initialize-FileConversion-BinarySchemaAvro with core conversion helpers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Initialize-FileConversion-BinarySchemaAvro'
        $c | Should -Match '_ConvertTo-AvroFromJson'
    }
    It 'Registers json-to-avro and avro-to-json entry points' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'json-to-avro'
        $c | Should -Match 'avro-to-json'
    }
}
