<#
tests/unit/profile-conversion-data-binary-binary-protocol-orc-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/conversion-modules/data/binary/binary-protocol-orc.ps1'
}
Describe 'profile.d/conversion-modules/data/binary/binary-protocol-orc.ps1 extended scenarios' {
    It 'Documents Apache ORC format conversion utilities' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Apache ORC format conversion utilities'
        $c | Should -Match 'Ensure-FileConversion-Data'
    }
    It 'Defines Initialize-FileConversion-BinaryProtocolOrc with core conversion helpers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Initialize-FileConversion-BinaryProtocolOrc'
        $c | Should -Match 'Get-PythonPath'
    }
    It 'Registers orc-to-json and json-to-orc entry points' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'orc-to-json'
        $c | Should -Match 'json-to-orc'
    }
}
