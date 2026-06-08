<#
tests/unit/profile-conversion-data-binary-binary-protocol-delta-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/conversion-modules/data/binary/binary-protocol-delta.ps1'
}
Describe 'profile.d/conversion-modules/data/binary/binary-protocol-delta.ps1 extended scenarios' {
    It 'Documents Delta Lake format conversion utilities' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Delta Lake format conversion utilities'
        $c | Should -Match 'Ensure-FileConversion-Data'
    }
    It 'Defines Initialize-FileConversion-BinaryProtocolDelta with core conversion helpers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Initialize-FileConversion-BinaryProtocolDelta'
        $c | Should -Match 'Get-PythonPath'
    }
    It 'Registers delta-to-json and json-to-delta entry points' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'delta-to-json'
        $c | Should -Match 'json-to-delta'
    }
}
