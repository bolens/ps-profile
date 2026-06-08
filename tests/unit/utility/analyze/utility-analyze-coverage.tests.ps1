<#
tests/unit/utility-analyze-coverage.tests.ps1

.SYNOPSIS
    Behavioral unit tests for analyze-coverage.ps1 when analysis paths are missing.
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

    It 'Writes coverage output under a custom OutputPath for a missing analysis path' {
        $outputDir = New-TestTempDirectory -Prefix 'AnalyzeCoverageOutput'
        $missingPath = Join-Path $outputDir 'missing-source'
        try {
            $result = Invoke-TestScriptFile -ScriptPath $script:AnalyzeCoverageScript -ArgumentList @(
                '-Path', $missingPath,
                '-OutputPath', $outputDir
            )

            $result.ExitCode | Should -Be 0
            $result.Output | Should -Match 'Path not found|No source files or test files'
            Test-Path -LiteralPath $outputDir | Should -Be $true
        }
        finally {
            if (Test-Path -LiteralPath $outputDir) {
                Remove-Item -LiteralPath $outputDir -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }
}
