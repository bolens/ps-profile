<#
tests/unit/utility-run-tools-integration-batch.tests.ps1

.SYNOPSIS
    Behavioral unit tests for run-tools-integration-batch.ps1 validation.
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
    $script:RunToolsBatchScript = Join-Path $script:TestRepoRoot 'scripts' 'utils' 'code-quality' 'run-tools-integration-batch.ps1'
    $ConfirmPreference = 'None'
}

Describe 'run-tools-integration-batch.ps1 execution' {
    It 'Fails when the tools integration subdirectory does not exist' {
        $result = Invoke-TestScriptFile -ScriptPath $script:RunToolsBatchScript -ArgumentList @(
            '-RepoRoot', $script:TestRepoRoot,
            '-RelativePath', 'definitely-not-a-tools-batch-xyz'
        )

        $result.ExitCode | Should -Be 2
        $result.Output | Should -Match 'Test directory not found'
    }

    It 'Fails when the tools integration directory contains no test files' {
        $tempRoot = New-TestTempDirectory -Prefix 'tools-batch-empty'
        $toolsDir = Join-Path $tempRoot 'tests' 'integration' 'tools' 'empty-batch'
        $runnerDir = Join-Path $tempRoot 'scripts' 'utils' 'code-quality'
        $null = New-Item -ItemType Directory -Path $toolsDir -Force
        $null = New-Item -ItemType Directory -Path $runnerDir -Force
        Copy-Item -LiteralPath (Join-Path $script:TestRepoRoot 'scripts' 'utils' 'code-quality' 'run-pester.ps1') `
            -Destination (Join-Path $runnerDir 'run-pester.ps1') -Force

        $result = Invoke-TestScriptFile -ScriptPath $script:RunToolsBatchScript -ArgumentList @(
            '-RepoRoot', $tempRoot,
            '-RelativePath', 'empty-batch'
        )

        $result.ExitCode | Should -Be 2
        $result.Output | Should -Match 'No \*\.tests\.ps1 files'
    }

    It 'Runs per-file tools tests using a stub Pester runner' {
        $tempRoot = New-TestTempDirectory -Prefix 'tools-batch-stub'
        $toolsDir = Join-Path $tempRoot 'tests' 'integration' 'tools' 'stub-batch'
        $runnerDir = Join-Path $tempRoot 'scripts' 'utils' 'code-quality'
        $null = New-Item -ItemType Directory -Path $toolsDir -Force
        $null = New-Item -ItemType Directory -Path $runnerDir -Force
        $null = New-Item -ItemType File -Path (Join-Path $toolsDir 'sample.tests.ps1') -Force

        $stubRunner = @'
param()
Write-Host 'Tests Passed: 1, Failed: 0, Skipped: 0'
exit 0
'@
        Set-Content -LiteralPath (Join-Path $runnerDir 'run-pester.ps1') -Value $stubRunner -Encoding UTF8

        $result = Invoke-TestScriptFile -ScriptPath $script:RunToolsBatchScript -ArgumentList @(
            '-RepoRoot', $tempRoot,
            '-RelativePath', 'stub-batch',
            '-Quiet'
        )

        $result.ExitCode | Should -Be 0
        $result.Output | Should -Match 'Batch: tools/stub-batch'
        $result.Output | Should -Match 'Mode: per-file'
        $result.Output | Should -Match '1P / 0F / 0S'
        $result.Output | Should -Match 'All tests passed in batch'
    }

    It 'Runs tools tests in a single session using a stub Pester runner' {
        $tempRoot = New-TestTempDirectory -Prefix 'tools-batch-singlesession'
        $toolsDir = Join-Path $tempRoot 'tests' 'integration' 'tools' 'session-batch'
        $runnerDir = Join-Path $tempRoot 'scripts' 'utils' 'code-quality'
        $null = New-Item -ItemType Directory -Path $toolsDir -Force
        $null = New-Item -ItemType Directory -Path $runnerDir -Force
        $null = New-Item -ItemType File -Path (Join-Path $toolsDir 'sample.tests.ps1') -Force

        $stubRunner = @'
param()
Write-Host 'Tests Passed: 2, Failed: 0, Skipped: 0'
exit 0
'@
        Set-Content -LiteralPath (Join-Path $runnerDir 'run-pester.ps1') -Value $stubRunner -Encoding UTF8

        $result = Invoke-TestScriptFile -ScriptPath $script:RunToolsBatchScript -ArgumentList @(
            '-RepoRoot', $tempRoot,
            '-RelativePath', 'session-batch',
            '-SingleSession',
            '-Quiet'
        )

        $result.ExitCode | Should -Be 0
        $result.Output | Should -Match 'Batch: tools/session-batch'
        $result.Output | Should -Match 'Mode: single session'
        $result.Output | Should -Match '2P / 0F / 0S'
        $result.Output | Should -Match 'All tests passed in batch'
    }

    It 'Fails the single-session batch when the stub Pester runner reports test failures' {
        $tempRoot = New-TestTempDirectory -Prefix 'tools-batch-singlesession-fail'
        $toolsDir = Join-Path $tempRoot 'tests' 'integration' 'tools' 'failing-session'
        $runnerDir = Join-Path $tempRoot 'scripts' 'utils' 'code-quality'
        $null = New-Item -ItemType Directory -Path $toolsDir -Force
        $null = New-Item -ItemType Directory -Path $runnerDir -Force
        $null = New-Item -ItemType File -Path (Join-Path $toolsDir 'failing.tests.ps1') -Force

        $stubRunner = @'
param()
Write-Host 'Tests Passed: 0, Failed: 1, Skipped: 0'
exit 1
'@
        Set-Content -LiteralPath (Join-Path $runnerDir 'run-pester.ps1') -Value $stubRunner -Encoding UTF8

        $result = Invoke-TestScriptFile -ScriptPath $script:RunToolsBatchScript -ArgumentList @(
            '-RepoRoot', $tempRoot,
            '-RelativePath', 'failing-session',
            '-SingleSession',
            '-Quiet'
        )

        $result.ExitCode | Should -Be 1
        $result.Output | Should -Match 'Mode: single session'
        $result.Output | Should -Match '0P / 1F / 0S|Batch failed'
    }

    It 'Fails the batch when the stub Pester runner reports test failures' {
        $tempRoot = New-TestTempDirectory -Prefix 'tools-batch-failure'
        $toolsDir = Join-Path $tempRoot 'tests' 'integration' 'tools' 'failing-batch'
        $runnerDir = Join-Path $tempRoot 'scripts' 'utils' 'code-quality'
        $null = New-Item -ItemType Directory -Path $toolsDir -Force
        $null = New-Item -ItemType Directory -Path $runnerDir -Force
        $null = New-Item -ItemType File -Path (Join-Path $toolsDir 'failing-sample.tests.ps1') -Force

        $stubRunner = @'
param()
Write-Host 'Tests Passed: 0, Failed: 1, Skipped: 0'
exit 1
'@
        Set-Content -LiteralPath (Join-Path $runnerDir 'run-pester.ps1') -Value $stubRunner -Encoding UTF8

        $result = Invoke-TestScriptFile -ScriptPath $script:RunToolsBatchScript -ArgumentList @(
            '-RepoRoot', $tempRoot,
            '-RelativePath', 'failing-batch',
            '-Quiet'
        )

        $result.ExitCode | Should -Be 1
        $result.Output | Should -Match 'Batch: tools/failing-batch'
        $result.Output | Should -Match '0P / 1F / 0S|failed'
    }

    It 'Discovers tools tests in nested subdirectories under the relative path' {
        $tempRoot = New-TestTempDirectory -Prefix 'tools-batch-nested'
        $nestedDir = Join-Path $tempRoot 'tests' 'integration' 'tools' 'stub-batch' 'nested' 'suite'
        $runnerDir = Join-Path $tempRoot 'scripts' 'utils' 'code-quality'
        $null = New-Item -ItemType Directory -Path $nestedDir -Force
        $null = New-Item -ItemType Directory -Path $runnerDir -Force
        $null = New-Item -ItemType File -Path (Join-Path $nestedDir 'nested-tools.tests.ps1') -Force

        $stubRunner = @'
param()
Write-Host 'Tests Passed: 1, Failed: 0, Skipped: 0'
exit 0
'@
        Set-Content -LiteralPath (Join-Path $runnerDir 'run-pester.ps1') -Value $stubRunner -Encoding UTF8

        $result = Invoke-TestScriptFile -ScriptPath $script:RunToolsBatchScript -ArgumentList @(
            '-RepoRoot', $tempRoot,
            '-RelativePath', 'stub-batch',
            '-Quiet'
        )

        $result.ExitCode | Should -Be 0
        $result.Output | Should -Match 'nested-tools\.tests\.ps1'
        $result.Output | Should -Match '1P / 0F / 0S'
    }
}
