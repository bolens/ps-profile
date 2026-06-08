<#
tests/unit/profile-conversion-data-binary-binary-protocol-iceberg-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/conversion-modules/data/binary/binary-protocol-iceberg.ps1'
}
Describe 'profile.d/conversion-modules/data/binary/binary-protocol-iceberg.ps1 extended scenarios' {
    It 'Documents Apache Iceberg format conversion utilities' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Apache Iceberg format conversion utilities'
        $c | Should -Match 'Ensure-FileConversion-Data'
    }
    It 'Defines Initialize-FileConversion-BinaryProtocolIceberg with core conversion helpers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Initialize-FileConversion-BinaryProtocolIceberg'
        $c | Should -Match 'Get-PythonPath'
    }
    It 'Registers iceberg-to-json and json-to-iceberg entry points' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'iceberg-to-json'
        $c | Should -Match 'json-to-iceberg'
    }
}
