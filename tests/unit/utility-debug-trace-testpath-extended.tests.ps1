<#
tests/unit/utility-debug-trace-testpath-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for scripts/utils/debug/trace-testpath.ps1.
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Script = Join-Path $script:TestRepoRoot 'scripts/utils/debug/trace-testpath.ps1'
}
Describe 'trace-testpath.ps1 extended scenarios' {
    It 'Documents mandatory TestFile parameter for traced test runs' {
        $c = Get-Content -LiteralPath $script:Script -Raw
        $c | Should -Match '\.PARAMETER TestFile'
    }
    It 'Enables PS_PROFILE_DEBUG_TESTPATH verbose tracing' {
        $c = Get-Content -LiteralPath $script:Script -Raw
        $c | Should -Match 'PS_PROFILE_DEBUG_TESTPATH'
    }
    It 'Wraps Test-Path to log null or empty path usage' {
        $c = Get-Content -LiteralPath $script:Script -Raw
        $c | Should -Match 'Test-Path'
        $c | Should -Match 'null/empty'
    }
}
