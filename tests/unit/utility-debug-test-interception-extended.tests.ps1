<#
tests/unit/utility-debug-test-interception-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for scripts/utils/debug/test-interception.ps1.
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Script = Join-Path $script:TestRepoRoot 'scripts/utils/debug/test-interception.ps1'
}
Describe 'test-interception.ps1 extended scenarios' {
    It 'Dot-sources intercept-testpath.ps1 before running tests' {
        $c = Get-Content -LiteralPath $script:Script -Raw
        $c | Should -Match 'intercept-testpath\.ps1'
    }
    It 'Runs test-support.tests.ps1 as the default interception smoke test' {
        $c = Get-Content -LiteralPath $script:Script -Raw
        $c | Should -Match 'test-support\.tests\.ps1'
    }
    It 'Exits with the Pester failed test count' {
        $c = Get-Content -LiteralPath $script:Script -Raw
        $c | Should -Match 'exit \$result\.FailedCount'
    }
}
