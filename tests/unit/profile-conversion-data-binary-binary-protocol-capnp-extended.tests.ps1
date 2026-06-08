<#
tests/unit/profile-conversion-data-binary-binary-protocol-capnp-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/conversion-modules/data/binary/binary-protocol-capnp.ps1'
}
Describe 'profile.d/conversion-modules/data/binary/binary-protocol-capnp.ps1 extended scenarios' {
    It 'Documents Cap n Proto format conversion utilities' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Cap''n Proto format conversion utilities'
        $c | Should -Match 'Ensure-FileConversion-Data'
    }
    It 'Defines Initialize-FileConversion-BinaryProtocolCapnp with core conversion helpers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Initialize-FileConversion-BinaryProtocolCapnp'
        $c | Should -Match 'Test-CachedCommand ''node'''
    }
    It 'Registers json-to-capnp and capnp-to-json entry points' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'json-to-capnp'
        $c | Should -Match 'capnp-to-json'
    }
}
