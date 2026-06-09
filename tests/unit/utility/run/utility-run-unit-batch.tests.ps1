<#
tests/unit/utility-run-unit-batch.tests.ps1

.SYNOPSIS
    Behavioral unit tests for run-unit-batch.ps1 filter validation.
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

    It 'Runs per-file unit tests using a stub Pester runner' {
        $tempRoot = New-TestTempDirectory -Prefix 'unit-batch-stub'
        $unitDir = Join-Path $tempRoot 'tests' 'unit'
        $runnerDir = Join-Path $tempRoot 'scripts' 'utils' 'code-quality'
        $null = New-Item -ItemType Directory -Path $unitDir -Force
        $null = New-Item -ItemType Directory -Path $runnerDir -Force
        $null = New-Item -ItemType File -Path (Join-Path $unitDir 'sample.tests.ps1') -Force

        $stubRunner = @'
param()
Write-Host 'Tests Passed: 1, Failed: 0, Skipped: 0'
exit 0
'@
        Set-Content -LiteralPath (Join-Path $runnerDir 'run-pester.ps1') -Value $stubRunner -Encoding UTF8

        $result = Invoke-TestScriptFile -ScriptPath $script:RunUnitBatchScript -ArgumentList @(
            '-RepoRoot', $tempRoot,
            '-Filter', 'sample',
            '-Quiet'
        )

        $result.ExitCode | Should -Be 0
        $result.Output | Should -Match 'Batch: unit \(sample\*\)'
        $result.Output | Should -Match '1P / 0F / 0S'
        $result.Output | Should -Match 'All tests passed in batch'
    }

    It 'Fails the batch when the stub Pester runner reports test failures' {
        $tempRoot = New-TestTempDirectory -Prefix 'unit-batch-failure'
        $unitDir = Join-Path $tempRoot 'tests' 'unit'
        $runnerDir = Join-Path $tempRoot 'scripts' 'utils' 'code-quality'
        $null = New-Item -ItemType Directory -Path $unitDir -Force
        $null = New-Item -ItemType Directory -Path $runnerDir -Force
        $null = New-Item -ItemType File -Path (Join-Path $unitDir 'failing-sample.tests.ps1') -Force

        $stubRunner = @'
param()
Write-Host 'Tests Passed: 0, Failed: 1, Skipped: 0'
exit 1
'@
        Set-Content -LiteralPath (Join-Path $runnerDir 'run-pester.ps1') -Value $stubRunner -Encoding UTF8

        $result = Invoke-TestScriptFile -ScriptPath $script:RunUnitBatchScript -ArgumentList @(
            '-RepoRoot', $tempRoot,
            '-Filter', 'failing-sample',
            '-Quiet'
        )

        $result.ExitCode | Should -Be 1
        $result.Output | Should -Match 'Batch: unit \(failing-sample\*\)'
        $result.Output | Should -Match '0P / 1F / 0S|failed'
    }

    It 'Discovers unit tests in nested subdirectories under tests/unit' {
        $tempRoot = New-TestTempDirectory -Prefix 'unit-batch-nested'
        $nestedDir = Join-Path $tempRoot 'tests' 'unit' 'nested' 'batch'
        $runnerDir = Join-Path $tempRoot 'scripts' 'utils' 'code-quality'
        $null = New-Item -ItemType Directory -Path $nestedDir -Force
        $null = New-Item -ItemType Directory -Path $runnerDir -Force
        $null = New-Item -ItemType File -Path (Join-Path $nestedDir 'nested-sample.tests.ps1') -Force

        $stubRunner = @'
param()
Write-Host 'Tests Passed: 1, Failed: 0, Skipped: 0'
exit 0
'@
        Set-Content -LiteralPath (Join-Path $runnerDir 'run-pester.ps1') -Value $stubRunner -Encoding UTF8

        $result = Invoke-TestScriptFile -ScriptPath $script:RunUnitBatchScript -ArgumentList @(
            '-RepoRoot', $tempRoot,
            '-Filter', 'nested-sample',
            '-Quiet'
        )

        $result.ExitCode | Should -Be 0
        $result.Output | Should -Match 'Batch: unit \(nested-sample\*\)'
        $result.Output | Should -Match '1P / 0F / 0S'
    }

    It 'Marks unparsed runner output as a crash failure in the batch summary' {
        $tempRoot = New-TestTempDirectory -Prefix 'unit-batch-crash'
        $unitDir = Join-Path $tempRoot 'tests' 'unit'
        $runnerDir = Join-Path $tempRoot 'scripts' 'utils' 'code-quality'
        $null = New-Item -ItemType Directory -Path $unitDir -Force
        $null = New-Item -ItemType Directory -Path $runnerDir -Force
        $null = New-Item -ItemType File -Path (Join-Path $unitDir 'crash-sample.tests.ps1') -Force

        $stubRunner = @'
param()
Write-Host 'FATAL: runner crashed before emitting stats'
exit 1
'@
        Set-Content -LiteralPath (Join-Path $runnerDir 'run-pester.ps1') -Value $stubRunner -Encoding UTF8

        $result = Invoke-TestScriptFile -ScriptPath $script:RunUnitBatchScript -ArgumentList @(
            '-RepoRoot', $tempRoot,
            '-Filter', 'crash-sample',
            '-Quiet'
        )

        $result.ExitCode | Should -Be 1
        $result.Output | Should -Match 'crash/unparsed'
        $result.Output | Should -Match '0P / 1F / 0S'
        $result.Output | Should -Match 'Files with failures'
    }
}
