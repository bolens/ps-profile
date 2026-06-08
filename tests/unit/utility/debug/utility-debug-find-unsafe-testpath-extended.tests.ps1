<#
tests/unit/utility-debug-find-unsafe-testpath-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for scripts/utils/debug/find-unsafe-testpath.ps1.
#>
BeforeAll {
    $current = Get-Item $PSScriptRoot
    while ($null -ne $current) {
        $testSupportPath = Join-Path $current.FullName 'TestSupport.ps1'
        if (Test-Path -LiteralPath $testSupportPath) {
            . $testSupportPath
            break
        }
        if ($current.Name -eq 'tests' -or $current.Parent -eq $null) { break }
        $current = $current.Parent
    }
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
