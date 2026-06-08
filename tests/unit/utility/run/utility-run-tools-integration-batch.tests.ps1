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
        try {
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
        finally {
            if (Test-Path -LiteralPath $tempRoot) {
                Remove-Item -LiteralPath $tempRoot -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }

    It 'Runs per-file tools tests using a stub Pester runner' {
        $tempRoot = New-TestTempDirectory -Prefix 'tools-batch-stub'
        try {
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
