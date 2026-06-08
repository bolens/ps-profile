<#
tests/unit/utility-debug-run-tests-with-trace-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for scripts/utils/debug/run-tests-with-trace.ps1.
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Script = Join-Path $script:TestRepoRoot 'scripts/utils/debug/run-tests-with-trace.ps1'
}
Describe 'run-tests-with-trace.ps1 extended scenarios' {
    It 'Enables PS_PROFILE_DEBUG_TESTPATH verbose tracing' {
        $c = Get-Content -LiteralPath $script:Script -Raw
        $c | Should -Match "PS_PROFILE_DEBUG_TESTPATH = 'verbose'"
    }
    It 'Requires TestFile and invokes Pester in a child process' {
        $c = Get-Content -LiteralPath $script:Script -Raw
        $c | Should -Match 'TestFile'
        $c | Should -Match 'Invoke-Pester'
        $c | Should -Match 'pwsh -NoProfile'
    }
    It 'Clears tracing environment in a finally block' {
        $c = Get-Content -LiteralPath $script:Script -Raw
        $c | Should -Match 'finally'
        $c | Should -Match 'Remove-Item Env:'
    }
}
