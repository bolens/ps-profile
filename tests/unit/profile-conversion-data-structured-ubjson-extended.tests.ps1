<#
tests/unit/profile-conversion-data-structured-ubjson-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/conversion-modules/data/structured/ubjson.ps1'
}
Describe 'profile.d/conversion-modules/data/structured/ubjson.ps1 extended scenarios' {
    It 'Documents UBJSON \(Universal Binary JSON\) format conversion utilities' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'UBJSON \(Universal Binary JSON\) format conversion utilities'
        $c | Should -Match 'Ensure-FileConversion-Data'
    }
    It 'Defines Initialize-FileConversion-Ubjson with core conversion helpers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Initialize-FileConversion-Ubjson'
        $c | Should -Match 'Test-CachedCommand ''node'''
    }
    It 'Registers ubjson-to-json and json-to-ubjson entry points' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'ubjson-to-json'
        $c | Should -Match 'json-to-ubjson'
    }
}
