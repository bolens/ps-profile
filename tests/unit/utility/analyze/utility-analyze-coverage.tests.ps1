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
            $result = Invoke-TestScriptFile -ScriptPath $script:AnalyzeCoverageScript -ArgumentList @(
                '-Path', $missingPath
            )

            $result.ExitCode | Should -Be 0
            $result.Output | Should -Match 'Path not found|No source files or test files'
    }

    It 'Writes coverage output under a custom OutputPath for a missing analysis path' {
        $outputDir = New-TestTempDirectory -Prefix 'AnalyzeCoverageOutput'
        $missingPath = Join-Path $outputDir 'missing-source'
            $result = Invoke-TestScriptFile -ScriptPath $script:AnalyzeCoverageScript -ArgumentList @(
                '-Path', $missingPath,
                '-OutputPath', $outputDir
            )

            $result.ExitCode | Should -Be 0
            $result.Output | Should -Match 'Path not found|No source files or test files'
            Test-Path -LiteralPath $outputDir | Should -Be $true
    }

    It 'Exits successfully when the analysis path exists but contains no PowerShell files' {
        $emptyDir = New-TestTempDirectory -Prefix 'AnalyzeCoverageEmptyDir'
            $result = Invoke-TestScriptFile -ScriptPath $script:AnalyzeCoverageScript -ArgumentList @(
                '-Path', $emptyDir
            )

            $result.ExitCode | Should -Be 0
            $result.Output | Should -Match 'No source files or test files|Path not found'
    }

    It 'Runs coverage analysis for a matched source and unit test pair in an isolated repository' {
        $repo = New-TestTempDirectory -Prefix 'AnalyzeCoverageMatched'
            $profileDir = Join-Path $repo 'profile.d'
            $unitDir = Join-Path $repo 'tests' 'unit'
            $codeQualityDir = Join-Path $repo 'scripts' 'utils' 'code-quality'
            $outputDir = Join-Path $repo 'coverage-output'
            $null = New-Item -ItemType Directory -Path $profileDir -Force
            $null = New-Item -ItemType Directory -Path $unitDir -Force
            $null = New-Item -ItemType Directory -Path $codeQualityDir -Force
            $null = New-Item -ItemType Directory -Path $outputDir -Force
            Copy-Item -LiteralPath (Join-Path $script:TestRepoRoot 'scripts' 'lib') -Destination (Join-Path $repo 'scripts' 'lib') -Recurse -Force
            Copy-Item -LiteralPath $script:AnalyzeCoverageScript -Destination (Join-Path $codeQualityDir 'analyze-coverage.ps1') -Force

            Set-Content -LiteralPath (Join-Path $profileDir 'coverage-fixture.ps1') -Value @'
function Get-CoverageFixtureValue {
    'ok'
}
'@ -Encoding UTF8
            Set-Content -LiteralPath (Join-Path $unitDir 'profile-coverage-fixture.tests.ps1') -Value @'
Describe 'coverage fixture' {
    It 'exercises the source function' {
        Get-CoverageFixtureValue | Should -Be 'ok'
    }
}
'@ -Encoding UTF8

            Push-Location $repo
            try {
                git init -q | Out-Null
                git config user.email 'fixture@example.com'
                git config user.name 'Fixture'

                $result = Invoke-TestScriptFile -ScriptPath (Join-Path $codeQualityDir 'analyze-coverage.ps1') -ArgumentList @(
                    '-Path', 'profile.d/coverage-fixture.ps1',
                    '-OutputPath', $outputDir
                )
            }
            finally {
                Pop-Location
            }

            $result.ExitCode | Should -BeIn @(0, 1)
            $result.Output | Should -Match 'Coverage Analysis Summary'
            $result.Output | Should -Match 'coverage-fixture\.ps1|profile-coverage-fixture'
    }
}
