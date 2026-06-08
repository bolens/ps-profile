<#
tests/unit/utility-debug-find-unsafe-testpath-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for scripts/utils/debug/find-unsafe-testpath.ps1.
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Script = Join-Path $script:TestRepoRoot 'scripts/utils/debug/find-unsafe-testpath.ps1'
}
Describe 'find-unsafe-testpath.ps1 extended scenarios' {
    It 'Searches profile.d scripts lib and tests for unsafe Test-Path usage' {
        $c = Get-Content -LiteralPath $script:Script -Raw
        $c | Should -Match 'profile\.d'
        $c | Should -Match 'scripts/lib'
        $c | Should -Match "'tests'"
    }
    It 'Uses regex patterns to detect missing null checks' {
        $c = Get-Content -LiteralPath $script:Script -Raw
        $c | Should -Match '\$patterns'
        $c | Should -Match 'Test-Path'
    }
    It 'Reports potentially unsafe Test-Path variable usage' {
        $c = Get-Content -LiteralPath $script:Script -Raw
        $c | Should -Match 'unsafe Test-Path'
    }
}
