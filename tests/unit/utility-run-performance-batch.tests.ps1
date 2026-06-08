<#
tests/unit/utility-run-performance-batch.tests.ps1

.SYNOPSIS
    Behavioral unit tests for run-performance-batch.ps1 filter validation.
#>

BeforeAll {
    . (Join-Path $PSScriptRoot '..\TestSupport.ps1')

    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:RunPerformanceBatchScript = Join-Path $script:TestRepoRoot 'scripts' 'utils' 'code-quality' 'run-performance-batch.ps1'
    $ConfirmPreference = 'None'
}

Describe 'run-performance-batch.ps1 execution' {
    It 'Fails when the filter matches no performance test files' {
        $result = Invoke-TestScriptFile -ScriptPath $script:RunPerformanceBatchScript -ArgumentList @(
            '-RepoRoot', $script:TestRepoRoot,
            '-Filter', 'definitely-no-performance-tests-match-xyz'
        )

        $result.ExitCode | Should -Be 2
        $result.Output | Should -Match 'No .* test files matched|performance'
    }
}
