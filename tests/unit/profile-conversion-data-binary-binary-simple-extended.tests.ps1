<#
tests/unit/profile-conversion-data-binary-binary-simple-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/conversion-modules/data/binary/binary-simple.ps1'
}
Describe 'profile.d/conversion-modules/data/binary/binary-simple.ps1 extended scenarios' {
    It 'Documents Simple binary format conversion utilities' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Simple binary format conversion utilities'
        $c | Should -Match 'Ensure-FileConversion-Data'
    }
    It 'Defines Initialize-FileConversion-BinarySimple with core conversion helpers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Initialize-FileConversion-BinarySimple'
        $c | Should -Match 'Test-CachedCommand ''node'''
    }
    It 'Registers json-to-bson and bson-to-json entry points' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'json-to-bson'
        $c | Should -Match 'bson-to-json'
    }
}
