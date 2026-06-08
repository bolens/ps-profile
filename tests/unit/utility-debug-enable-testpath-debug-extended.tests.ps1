<#
tests/unit/utility-debug-enable-testpath-debug-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for scripts/utils/debug/enable-testpath-debug.ps1.
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Script = Join-Path $script:TestRepoRoot 'scripts/utils/debug/enable-testpath-debug.ps1'
}
Describe 'enable-testpath-debug.ps1 extended scenarios' {
    It 'Documents enabling Test-Path debug logging via environment variable' {
        $c = Get-Content -LiteralPath $script:Script -Raw
        $c | Should -Match 'PS_PROFILE_DEBUG_TESTPATH'
        $c | Should -Match 'Test-SafePath'
    }
    It 'Sets verbose tracing mode when executed' {
        $c = Get-Content -LiteralPath $script:Script -Raw
        $c | Should -Match "PS_PROFILE_DEBUG_TESTPATH = 'verbose'"
    }
    It 'Documents run-pester usage in comment-based help example' {
        $c = Get-Content -LiteralPath $script:Script -Raw
        $c | Should -Match 'run-pester\.ps1'
    }
}
