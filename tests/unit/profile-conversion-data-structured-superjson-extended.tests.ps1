<#
tests/unit/profile-conversion-data-structured-superjson-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/conversion-modules/data/structured/superjson.ps1'
}
Describe 'profile.d/conversion-modules/data/structured/superjson.ps1 extended scenarios' {
    It 'Documents SuperJSON conversion utilities' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'SuperJSON conversion utilities'
        $c | Should -Match 'Ensure-FileConversion-Data'
    }
    It 'Defines Initialize-FileConversion-SuperJson with core conversion helpers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Initialize-FileConversion-SuperJson'
        $c | Should -Match 'Test-CachedCommand ''node'''
    }
    It 'Registers json-to-superjson and superjson-to-json entry points' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'json-to-superjson'
        $c | Should -Match 'superjson-to-json'
    }
}
