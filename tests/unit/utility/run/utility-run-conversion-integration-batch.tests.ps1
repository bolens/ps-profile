<#
tests/unit/utility-run-conversion-integration-batch.tests.ps1

.SYNOPSIS
    Behavioral unit tests for run-conversion-integration-batch.ps1 validation.
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
    $script:RunConversionBatchScript = Join-Path $script:TestRepoRoot 'scripts' 'utils' 'code-quality' 'run-conversion-integration-batch.ps1'
    $ConfirmPreference = 'None'
}

Describe 'run-conversion-integration-batch.ps1 execution' {
    It 'Fails when the relative path does not exist under conversion integration tests' {
        $result = Invoke-TestScriptFile -ScriptPath $script:RunConversionBatchScript -ArgumentList @(
            '-RepoRoot', $script:TestRepoRoot,
            '-RelativePath', 'definitely-not-a-conversion-batch-xyz'
        )

        $result.ExitCode | Should -Be 2
        $result.Output | Should -Match 'Test directory not found'
    }

    It 'Fails when the conversion batch directory contains no test files' {
        $tempRoot = New-TestTempDirectory -Prefix 'conversion-batch-empty'
        try {
            $conversionDir = Join-Path $tempRoot 'tests' 'integration' 'conversion' 'empty-batch'
            $runnerDir = Join-Path $tempRoot 'scripts' 'utils' 'code-quality'
            $null = New-Item -ItemType Directory -Path $conversionDir -Force
            $null = New-Item -ItemType Directory -Path $runnerDir -Force
            Copy-Item -LiteralPath (Join-Path $script:TestRepoRoot 'scripts' 'utils' 'code-quality' 'run-pester.ps1') `
                -Destination (Join-Path $runnerDir 'run-pester.ps1') -Force

            $result = Invoke-TestScriptFile -ScriptPath $script:RunConversionBatchScript -ArgumentList @(
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

    It 'Runs conversion tests in a single session using a stub Pester runner' {
        $tempRoot = New-TestTempDirectory -Prefix 'conversion-batch-stub'
        try {
            $conversionDir = Join-Path $tempRoot 'tests' 'integration' 'conversion' 'stub-batch'
            $runnerDir = Join-Path $tempRoot 'scripts' 'utils' 'code-quality'
            $null = New-Item -ItemType Directory -Path $conversionDir -Force
            $null = New-Item -ItemType Directory -Path $runnerDir -Force
            $null = New-Item -ItemType File -Path (Join-Path $conversionDir 'sample.tests.ps1') -Force

            $stubRunner = @'
param()
Write-Host 'Tests Passed: 1, Failed: 0, Skipped: 0'
exit 0
'@
            Set-Content -LiteralPath (Join-Path $runnerDir 'run-pester.ps1') -Value $stubRunner -Encoding UTF8

            $result = Invoke-TestScriptFile -ScriptPath $script:RunConversionBatchScript -ArgumentList @(
                '-RepoRoot', $tempRoot,
                '-RelativePath', 'stub-batch',
                '-Quiet'
            )

            $result.ExitCode | Should -Be 0
            $result.Output | Should -Match 'Batch: stub-batch'
            $result.Output | Should -Match 'single session'
            $result.Output | Should -Match '1P / 0F / 0S'
            $result.Output | Should -Match 'All tests passed in batch'
        }
        finally {
            if (Test-Path -LiteralPath $tempRoot) {
                Remove-Item -LiteralPath $tempRoot -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }

    It 'Runs conversion tests per-file using a stub Pester runner' {
        $tempRoot = New-TestTempDirectory -Prefix 'conversion-batch-perfile'
        try {
            $conversionDir = Join-Path $tempRoot 'tests' 'integration' 'conversion' 'perfile-batch'
            $runnerDir = Join-Path $tempRoot 'scripts' 'utils' 'code-quality'
            $null = New-Item -ItemType Directory -Path $conversionDir -Force
            $null = New-Item -ItemType Directory -Path $runnerDir -Force
            $null = New-Item -ItemType File -Path (Join-Path $conversionDir 'sample.tests.ps1') -Force

            $stubRunner = @'
param()
Write-Host 'Tests Passed: 1, Failed: 0, Skipped: 0'
exit 0
'@
            Set-Content -LiteralPath (Join-Path $runnerDir 'run-pester.ps1') -Value $stubRunner -Encoding UTF8

            $result = Invoke-TestScriptFile -ScriptPath $script:RunConversionBatchScript -ArgumentList @(
                '-RepoRoot', $tempRoot,
                '-RelativePath', 'perfile-batch',
                '-PerFile',
                '-Quiet'
            )

            $result.ExitCode | Should -Be 0
            $result.Output | Should -Match 'Mode: per-file'
            $result.Output | Should -Match 'sample\.tests\.ps1'
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
