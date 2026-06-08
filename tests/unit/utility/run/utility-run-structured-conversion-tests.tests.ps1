<#
tests/unit/utility-run-structured-conversion-tests.tests.ps1

.SYNOPSIS
    Behavioral unit tests for run-structured-conversion-tests.ps1.
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
    $script:RunStructuredConversionScript = Join-Path $script:TestRepoRoot 'scripts' 'utils' 'code-quality' 'run-structured-conversion-tests.ps1'
    $ConfirmPreference = 'None'
}

Describe 'run-structured-conversion-tests.ps1 execution' {
    It 'Completes when the structured conversion directory has no test files' {
        $tempRoot = New-TestTempDirectory -Prefix 'structured-conversion-empty'
        try {
            $structuredDir = Join-Path $tempRoot 'tests' 'integration' 'conversion' 'data' 'structured'
            $null = New-Item -ItemType Directory -Path $structuredDir -Force

            $result = Invoke-TestScriptFile -ScriptPath $script:RunStructuredConversionScript -ArgumentList @(
                '-RepoRoot', $tempRoot
            )

            $result.ExitCode | Should -Be 0
            $result.Output | Should -Match 'All structured tests passed'
        }
        finally {
            if (Test-Path -LiteralPath $tempRoot) {
                Remove-Item -LiteralPath $tempRoot -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }

    It 'Runs per-file structured tests using a stub Pester runner' {
        $tempRoot = New-TestTempDirectory -Prefix 'structured-conversion-stub'
        try {
            $structuredDir = Join-Path $tempRoot 'tests' 'integration' 'conversion' 'data' 'structured'
            $runnerDir = Join-Path $tempRoot 'scripts' 'utils' 'code-quality'
            $null = New-Item -ItemType Directory -Path $structuredDir -Force
            $null = New-Item -ItemType Directory -Path $runnerDir -Force
            $null = New-Item -ItemType File -Path (Join-Path $structuredDir 'sample-structured.tests.ps1') -Force

            $stubRunner = @'
param(
    [string]$Suite,
    [string]$Path
)
Write-Host 'Tests Passed: 1, Failed: 0, Skipped: 0'
exit 0
'@
            Set-Content -LiteralPath (Join-Path $runnerDir 'run-pester.ps1') -Value $stubRunner -Encoding UTF8

            $result = Invoke-TestScriptFile -ScriptPath $script:RunStructuredConversionScript -ArgumentList @(
                '-RepoRoot', $tempRoot
            )

            $result.ExitCode | Should -Be 0
            $result.Output | Should -Match 'sample-structured\.tests\.ps1'
            $result.Output | Should -Match '1P / 0F / 0S'
            $result.Output | Should -Match 'All structured tests passed'
        }
        finally {
            if (Test-Path -LiteralPath $tempRoot) {
                Remove-Item -LiteralPath $tempRoot -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }

    It 'Fails when the stub Pester runner reports structured test failures' {
        $tempRoot = New-TestTempDirectory -Prefix 'structured-conversion-failure'
        try {
            $structuredDir = Join-Path $tempRoot 'tests' 'integration' 'conversion' 'data' 'structured'
            $runnerDir = Join-Path $tempRoot 'scripts' 'utils' 'code-quality'
            $null = New-Item -ItemType Directory -Path $structuredDir -Force
            $null = New-Item -ItemType Directory -Path $runnerDir -Force
            $null = New-Item -ItemType File -Path (Join-Path $structuredDir 'failing-structured.tests.ps1') -Force

            $stubRunner = @'
param([string]$Suite, [string]$Path)
Write-Host 'Tests Passed: 0, Failed: 1, Skipped: 0'
exit 1
'@
            Set-Content -LiteralPath (Join-Path $runnerDir 'run-pester.ps1') -Value $stubRunner -Encoding UTF8

            $result = Invoke-TestScriptFile -ScriptPath $script:RunStructuredConversionScript -ArgumentList @(
                '-RepoRoot', $tempRoot
            )

            $result.ExitCode | Should -Be 1
            $result.Output | Should -Match 'failing-structured\.tests\.ps1'
            $result.Output | Should -Match '0P / 1F / 0S'
            $result.Output | Should -Match 'Files with failures'
        }
        finally {
            if (Test-Path -LiteralPath $tempRoot) {
                Remove-Item -LiteralPath $tempRoot -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }

    It 'Runs structured conversion integration tests in the repository' {
        if ($env:CI -or $env:GITHUB_ACTIONS -or $env:PS_PROFILE_RUN_SLOW_TESTS -ne '1') {
            Set-ItResult -Skipped -Because 'set PS_PROFILE_RUN_SLOW_TESTS=1 to run per-file structured conversion batch locally'
            return
        }

        $structuredDir = Join-Path $script:TestRepoRoot 'tests' 'integration' 'conversion' 'data' 'structured'
        if (-not (Test-Path -LiteralPath $structuredDir)) {
            Set-ItResult -Skipped -Because 'structured conversion integration tests are not present'
            return
        }

        $result = Invoke-TestScriptFile -ScriptPath $script:RunStructuredConversionScript -ArgumentList @(
            '-RepoRoot', $script:TestRepoRoot
        )

        $result.Output | Should -Match '--- Summary ---|All structured tests passed|Files with failures'
        $result.ExitCode | Should -BeIn @(0, 1)
    }
}
