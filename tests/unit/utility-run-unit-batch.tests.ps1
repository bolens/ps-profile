<#
tests/unit/utility-run-unit-batch.tests.ps1

.SYNOPSIS
    Behavioral unit tests for run-unit-batch.ps1 filter validation.
#>

BeforeAll {
    . (Join-Path $PSScriptRoot '..\TestSupport.ps1')

    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:RunUnitBatchScript = Join-Path $script:TestRepoRoot 'scripts' 'utils' 'code-quality' 'run-unit-batch.ps1'
    $ConfirmPreference = 'None'
}

Describe 'run-unit-batch.ps1 execution' {
    It 'Fails when the filter matches no unit test files' {
        $result = Invoke-TestScriptFile -ScriptPath $script:RunUnitBatchScript -ArgumentList @(
            '-RepoRoot', $script:TestRepoRoot,
            '-Filter', 'definitely-no-unit-tests-match-xyz'
        )

        $result.ExitCode | Should -Be 2
        $result.Output | Should -Match 'No unit test files matched'
    }
}
