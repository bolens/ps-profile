<#
tests/unit/profile-conversion-data-binary-binary-direct-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/conversion-modules/data/binary/binary-direct.ps1'
}
Describe 'profile.d/conversion-modules/data/binary/binary-direct.ps1 extended scenarios' {
    It 'Documents Binary-to-binary direct conversion utilities' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Binary-to-binary direct conversion utilities'
        $c | Should -Match 'Ensure-FileConversion-Data'
    }
    It 'Defines Initialize-FileConversion-BinaryDirect with core conversion helpers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Initialize-FileConversion-BinaryDirect'
        $c | Should -Match '_ConvertTo-MessagePackFromBson'
    }
    It 'Registers bson-to-msgpack and msgpack-to-bson entry points' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'bson-to-msgpack'
        $c | Should -Match 'msgpack-to-bson'
    }
}
