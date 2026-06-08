<#
tests/unit/profile-conversion-data-binary-binary-schema-protobuf-extended.tests.ps1
#>
BeforeAll {
    $current = Get-Item $PSScriptRoot
    while ($null -ne $current) {
        $testSupportPath = Join-Path $current.FullName 'TestSupport.ps1'
        if (Test-Path -LiteralPath $testSupportPath) {
            . $testSupportPath
            break
        }
        if ($current.Name -eq 'tests' -or $current.Parent -eq $null) { break }
        $current = $current.Parent
    }
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/conversion-modules/data/binary/binary-schema-protobuf.ps1'
}
Describe 'profile.d/conversion-modules/data/binary/binary-schema-protobuf.ps1 extended scenarios' {
    It 'Documents Protocol Buffers (protobuf) schema conversion utilities' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Protocol Buffers \(protobuf\) schema conversion utilities'
        $c | Should -Match 'Ensure-FileConversion-Data'
    }
    It 'Defines Initialize-FileConversion-BinarySchemaProtobuf with core conversion helpers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Initialize-FileConversion-BinarySchemaProtobuf'
        $c | Should -Match '_ConvertTo-ProtobufFromJson'
    }
    It 'Registers json-to-protobuf and protobuf-to-json entry points' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'json-to-protobuf'
        $c | Should -Match 'protobuf-to-json'
    }
}
