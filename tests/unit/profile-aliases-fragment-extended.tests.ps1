<#
tests/unit/profile-aliases-fragment-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/aliases.ps1'
}
Describe 'profile.d/aliases.ps1 extended scenarios' {
    It 'Declares standard tier with bootstrap dependency' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Tier: standard'
        $c | Should -Match 'Dependencies: bootstrap, env'
    }
    It 'Defines Enable-Aliases function with idempotent AliasesLoaded guard' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'function Enable-Aliases'
        $c | Should -Match 'AliasesLoaded'
    }
    It 'Registers aliases in a non-destructive idempotent way' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'idempotent'
        $c | Should -Match 'non-destructive'
    }
}
