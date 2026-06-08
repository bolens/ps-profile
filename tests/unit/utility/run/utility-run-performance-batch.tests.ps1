<#
tests/unit/utility-run-performance-batch.tests.ps1

.SYNOPSIS
    Behavioral unit tests for run-performance-batch.ps1 filter validation.
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

    It 'Runs per-file performance tests using a stub Pester runner' {
        $tempRoot = New-TestTempDirectory -Prefix 'performance-batch-stub'
        try {
            $perfDir = Join-Path $tempRoot 'tests' 'performance'
            $runnerDir = Join-Path $tempRoot 'scripts' 'utils' 'code-quality'
            $null = New-Item -ItemType Directory -Path $perfDir -Force
            $null = New-Item -ItemType Directory -Path $runnerDir -Force
            $null = New-Item -ItemType File -Path (Join-Path $perfDir 'sample-performance.tests.ps1') -Force

            $stubRunner = @'
param()
Write-Host 'Tests Passed: 1, Failed: 0, Skipped: 0'
exit 0
'@
            Set-Content -LiteralPath (Join-Path $runnerDir 'run-pester.ps1') -Value $stubRunner -Encoding UTF8

            $result = Invoke-TestScriptFile -ScriptPath $script:RunPerformanceBatchScript -ArgumentList @(
                '-RepoRoot', $tempRoot,
                '-Filter', 'sample-performance',
                '-Quiet'
            )

            $result.ExitCode | Should -Be 0
            $result.Output | Should -Match 'Batch: performance \(sample-performance\*\)'
            $result.Output | Should -Match '1P / 0F / 0S'
            $result.Output | Should -Match 'All tests passed in batch'
        }
        finally {
            if (Test-Path -LiteralPath $tempRoot) {
                Remove-Item -LiteralPath $tempRoot -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }
}
