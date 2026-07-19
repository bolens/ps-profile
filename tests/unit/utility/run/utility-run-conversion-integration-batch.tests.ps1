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

    It 'Runs conversion tests in a single session using a stub Pester runner' {
        $tempRoot = New-TestTempDirectory -Prefix 'conversion-batch-stub'
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

    It 'Runs conversion tests per-file using a stub Pester runner' {
        $tempRoot = New-TestTempDirectory -Prefix 'conversion-batch-perfile'
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

    It 'Fails the batch when the stub Pester runner reports test failures' {
        $tempRoot = New-TestTempDirectory -Prefix 'conversion-batch-failure'
            $conversionDir = Join-Path $tempRoot 'tests' 'integration' 'conversion' 'failing-batch'
            $runnerDir = Join-Path $tempRoot 'scripts' 'utils' 'code-quality'
            $null = New-Item -ItemType Directory -Path $conversionDir -Force
            $null = New-Item -ItemType Directory -Path $runnerDir -Force
            $null = New-Item -ItemType File -Path (Join-Path $conversionDir 'failing.tests.ps1') -Force

            $stubRunner = @'
param()
Write-Host 'Tests Passed: 0, Failed: 1, Skipped: 0'
exit 1
'@
            Set-Content -LiteralPath (Join-Path $runnerDir 'run-pester.ps1') -Value $stubRunner -Encoding UTF8

            $result = Invoke-TestScriptFile -ScriptPath $script:RunConversionBatchScript -ArgumentList @(
                '-RepoRoot', $tempRoot,
                '-RelativePath', 'failing-batch',
                '-Quiet'
            )

            $result.ExitCode | Should -Be 1
            $result.Output | Should -Match 'Batch: failing-batch'
            $result.Output | Should -Match '0P / 1F / 0S|failed'
    }

    It 'Filters by NamePattern and passes matching files via a single -Path binding' {
        $tempRoot = New-TestTempDirectory -Prefix 'conversion-batch-namepattern'
        $conversionDir = Join-Path $tempRoot 'tests' 'integration' 'conversion' 'np-batch'
        $runnerDir = Join-Path $tempRoot 'scripts' 'utils' 'code-quality'
        $null = New-Item -ItemType Directory -Path $conversionDir -Force
        $null = New-Item -ItemType Directory -Path $runnerDir -Force
        $null = New-Item -ItemType File -Path (Join-Path $conversionDir 'alpha.tests.ps1') -Force
        $null = New-Item -ItemType File -Path (Join-Path $conversionDir 'beta.tests.ps1') -Force
        $null = New-Item -ItemType File -Path (Join-Path $conversionDir 'zeta.tests.ps1') -Force

        $stubRunner = @'
param(
    [Alias('Path')]
    [string[]]$TestFile
)
$path = @($TestFile)[0]
if (-not $path -or -not (Test-Path -LiteralPath $path -PathType Container)) {
    Write-Error "expected staged directory -Path, got: $path"
    exit 2
}
$names = @(Get-ChildItem -LiteralPath $path -Filter '*.tests.ps1' -File | Select-Object -ExpandProperty Name)
if ($names -contains 'zeta.tests.ps1') { Write-Error 'NamePattern leaked non-matching file'; exit 2 }
if ($names -notcontains 'alpha.tests.ps1' -or $names -notcontains 'beta.tests.ps1') {
    Write-Error "expected alpha+beta, got: $($names -join ',')"
    exit 2
}
Write-Host 'Tests Passed: 2, Failed: 0, Skipped: 0'
exit 0
'@
        Set-Content -LiteralPath (Join-Path $runnerDir 'run-pester.ps1') -Value $stubRunner -Encoding UTF8

        $result = Invoke-TestScriptFile -ScriptPath $script:RunConversionBatchScript -ArgumentList @(
            '-RepoRoot', $tempRoot,
            '-RelativePath', 'np-batch',
            '-NamePattern', '^[a-m]',
            '-Quiet'
        )

        $result.ExitCode | Should -Be 0
        $result.Output | Should -Match 'NamePattern=\^\[a-m\]'
        $result.Output | Should -Match '\(2 files\)'
        $result.Output | Should -Match '2P / 0F / 0S'
        $result.Output | Should -Match 'All tests passed in batch'
    }

    It 'Fails when NamePattern matches no files' {
        $tempRoot = New-TestTempDirectory -Prefix 'conversion-batch-np-empty'
        $conversionDir = Join-Path $tempRoot 'tests' 'integration' 'conversion' 'np-empty'
        $runnerDir = Join-Path $tempRoot 'scripts' 'utils' 'code-quality'
        $null = New-Item -ItemType Directory -Path $conversionDir -Force
        $null = New-Item -ItemType Directory -Path $runnerDir -Force
        $null = New-Item -ItemType File -Path (Join-Path $conversionDir 'zeta.tests.ps1') -Force
        Set-Content -LiteralPath (Join-Path $runnerDir 'run-pester.ps1') -Value 'param(); exit 0' -Encoding UTF8

        $result = Invoke-TestScriptFile -ScriptPath $script:RunConversionBatchScript -ArgumentList @(
            '-RepoRoot', $tempRoot,
            '-RelativePath', 'np-empty',
            '-NamePattern', '^[a-m]'
        )

        $result.ExitCode | Should -Be 2
        $result.Output | Should -Match 'No \*\.tests\.ps1 files'
        $result.Output | Should -Match 'NamePattern'
    }
}
