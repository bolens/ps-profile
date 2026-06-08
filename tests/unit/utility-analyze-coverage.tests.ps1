<#
tests/unit/utility-analyze-coverage.tests.ps1

.SYNOPSIS
    Behavioral unit tests for analyze-coverage.ps1 when analysis paths are missing.
#>

BeforeAll {
    . (Join-Path $PSScriptRoot '..\TestSupport.ps1')

    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:AnalyzeCoverageScript = Join-Path $script:TestRepoRoot 'scripts' 'utils' 'code-quality' 'analyze-coverage.ps1'
    $ConfirmPreference = 'None'
}

Describe 'analyze-coverage.ps1 execution' {
    It 'Exits successfully when no source or test files match the requested path' {
        $missingPath = Join-Path (New-TestTempDirectory -Prefix 'AnalyzeCoverageMissing') 'does-not-exist'
        try {
            $result = Invoke-TestScriptFile -ScriptPath $script:AnalyzeCoverageScript -ArgumentList @(
                '-Path', $missingPath
            )

            $result.ExitCode | Should -Be 0
            $result.Output | Should -Match 'Path not found|No source files or test files'
        }
        finally {
            $parent = Split-Path -Parent $missingPath
            if (Test-Path -LiteralPath $parent) {
                Remove-Item -LiteralPath $parent -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }
}
