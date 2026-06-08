<#
tests/unit/profile-conversion-data-binary-binary-schema-flatbuffers-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/conversion-modules/data/binary/binary-schema-flatbuffers.ps1'
}
Describe 'profile.d/conversion-modules/data/binary/binary-schema-flatbuffers.ps1 extended scenarios' {
    It 'Documents FlatBuffers schema conversion utilities' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'FlatBuffers schema conversion utilities'
        $c | Should -Match 'Ensure-FileConversion-Data'
    }
    It 'Defines Initialize-FileConversion-BinarySchemaFlatBuffers with core conversion helpers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Initialize-FileConversion-BinarySchemaFlatBuffers'
        $c | Should -Match 'Test-CachedCommand ''node'''
    }
    It 'Registers json-to-flatbuffers and flatbuffers-to-json entry points' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'json-to-flatbuffers'
        $c | Should -Match 'flatbuffers-to-json'
    }
}
