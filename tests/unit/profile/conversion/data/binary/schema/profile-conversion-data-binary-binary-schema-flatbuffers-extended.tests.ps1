<#
tests/unit/profile-conversion-data-binary-binary-schema-flatbuffers-extended.tests.ps1
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
