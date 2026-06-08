<#
tests/unit/profile-conversion-data-binary-binary-schema-thrift-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/conversion-modules/data/binary/binary-schema-thrift.ps1'
}
Describe 'profile.d/conversion-modules/data/binary/binary-schema-thrift.ps1 extended scenarios' {
    It 'Documents Thrift schema conversion utilities' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Thrift schema conversion utilities'
        $c | Should -Match 'Ensure-FileConversion-Data'
    }
    It 'Defines Initialize-FileConversion-BinarySchemaThrift with core conversion helpers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Initialize-FileConversion-BinarySchemaThrift'
        $c | Should -Match '_ConvertTo-ThriftFromJson'
    }
    It 'Registers json-to-thrift and thrift-to-json entry points' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'json-to-thrift'
        $c | Should -Match 'thrift-to-json'
    }
}
