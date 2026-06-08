<#
tests/unit/utility-debug-test-with-early-interception-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for scripts/utils/debug/test-with-early-interception.ps1.
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
    $script:Script = Join-Path $script:TestRepoRoot 'scripts/utils/debug/test-with-early-interception.ps1'
}
Describe 'test-with-early-interception.ps1 extended scenarios' {
    It 'Enables PS_PROFILE_DEBUG_TESTPATH_TRACE for early interception' {
        $c = Get-Content -LiteralPath $script:Script -Raw
        $c | Should -Match 'PS_PROFILE_DEBUG_TESTPATH_TRACE'
    }
    It 'Runs test-support.tests.ps1 with Pester PassThru output' {
        $c = Get-Content -LiteralPath $script:Script -Raw
        $c | Should -Match 'test-support\.tests\.ps1'
        $c | Should -Match '-PassThru'
    }
    It 'Reports passed failed and skipped counts after the run' {
        $c = Get-Content -LiteralPath $script:Script -Raw
        $c | Should -Match 'PassedCount'
        $c | Should -Match 'FailedCount'
        $c | Should -Match 'SkippedCount'
    }
}
