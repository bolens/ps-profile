<#
tests/unit/utility-trace-testpath.tests.ps1

.SYNOPSIS
    Behavioral unit tests for trace-testpath.ps1 with a narrow test file target.
#>

BeforeAll {
    . (Join-Path $PSScriptRoot '..\TestSupport.ps1')

    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:TraceTestPathScript = Join-Path $script:TestRepoRoot 'scripts' 'utils' 'debug' 'trace-testpath.ps1'
    $script:TargetTestFile = Join-Path $script:TestRepoRoot 'tests' 'unit' 'test-support.tests.ps1'
    $ConfirmPreference = 'None'
}

Describe 'trace-testpath.ps1 execution' {
    It 'Runs a targeted unit test file with Test-Path tracing enabled' {
        if (-not (Test-Path -LiteralPath $script:TargetTestFile)) {
            Set-ItResult -Skipped -Because 'test-support.tests.ps1 is not present'
            return
        }

        $result = Invoke-TestScriptFile -ScriptPath $script:TraceTestPathScript -ArgumentList @(
            '-TestFile', $script:TargetTestFile
        )

        $result.ExitCode | Should -BeIn @(0, 1)
        $result.Output | Should -Match 'Test-Path Tracing Enabled|test-support'
    }
}
