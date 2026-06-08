<#
tests/unit/utility-run-conversion-all-batch.tests.ps1

.SYNOPSIS
    Behavioral unit tests for run-conversion-all-batch.ps1 validation.
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
    $script:RunConversionAllBatchScript = Join-Path $script:TestRepoRoot 'scripts' 'utils' 'code-quality' 'run-conversion-all-batch.ps1'
    $ConfirmPreference = 'None'
}

Describe 'run-conversion-all-batch.ps1 execution' {
    It 'Fails when a requested sub-batch path does not exist' {
        $result = Invoke-TestScriptFile -ScriptPath $script:RunConversionAllBatchScript -ArgumentList @(
            '-RepoRoot', $script:TestRepoRoot,
            '-RelativePath', 'definitely-not-a-conversion-all-batch-xyz',
            '-Quiet'
        )

        $result.ExitCode | Should -Be 1
        $result.Output | Should -Match 'Test directory not found|Sub-batches with failures'
    }

    It 'Runs a single sub-batch via RelativePath using a stub integration runner' {
        $tempRepo = New-TestTempDirectory -Prefix 'ConversionAllStubRepo'
        try {
            $runnerDir = Join-Path $tempRepo 'scripts' 'utils' 'code-quality'
            $conversionDir = Join-Path $tempRepo 'tests' 'integration' 'conversion' 'document'
            $null = New-Item -ItemType Directory -Path $runnerDir -Force
            $null = New-Item -ItemType Directory -Path $conversionDir -Force
            $null = New-Item -ItemType File -Path (Join-Path $conversionDir 'sample.tests.ps1') -Force

            $stubRunner = @'
param([string]$RelativePath)
Write-Host '1P / 0F / 0S'
exit 0
'@
            Set-Content -LiteralPath (Join-Path $runnerDir 'run-conversion-integration-batch.ps1') -Value $stubRunner -Encoding UTF8

            $result = Invoke-TestScriptFile -ScriptPath $script:RunConversionAllBatchScript -ArgumentList @(
                '-RepoRoot', $tempRepo,
                '-RelativePath', 'document',
                '-Quiet'
            )

            $result.ExitCode | Should -Be 0
            $result.Output | Should -Match 'Conversion all-batch'
            $result.Output | Should -Match '1P / 0F / 0S'
        }
        finally {
            if (Test-Path -LiteralPath $tempRepo) {
                Remove-Item -LiteralPath $tempRepo -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }

    It 'Fails the batch when the stub integration runner reports failures' {
        $tempRepo = New-TestTempDirectory -Prefix 'ConversionAllFailureStub'
        try {
            $runnerDir = Join-Path $tempRepo 'scripts' 'utils' 'code-quality'
            $conversionDir = Join-Path $tempRepo 'tests' 'integration' 'conversion' 'document'
            $null = New-Item -ItemType Directory -Path $runnerDir -Force
            $null = New-Item -ItemType Directory -Path $conversionDir -Force
            $null = New-Item -ItemType File -Path (Join-Path $conversionDir 'failing-sample.tests.ps1') -Force

            $stubRunner = @'
param([string]$RelativePath)
Write-Host '0P / 1F / 0S'
exit 1
'@
            Set-Content -LiteralPath (Join-Path $runnerDir 'run-conversion-integration-batch.ps1') -Value $stubRunner -Encoding UTF8

            $result = Invoke-TestScriptFile -ScriptPath $script:RunConversionAllBatchScript -ArgumentList @(
                '-RepoRoot', $tempRepo,
                '-RelativePath', 'document',
                '-Quiet'
            )

            $result.ExitCode | Should -Be 1
            $result.Output | Should -Match 'Conversion all-batch|Sub-batches with failures|0P / 1F / 0S'
        }
        finally {
            if (Test-Path -LiteralPath $tempRepo) {
                Remove-Item -LiteralPath $tempRepo -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }
}
