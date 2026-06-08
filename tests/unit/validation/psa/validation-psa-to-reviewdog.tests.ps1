<#
tests/unit/validation-psa-to-reviewdog.tests.ps1

.SYNOPSIS
    Behavioral unit tests for .github/scripts/psa_to_reviewdog.ps1 conversion.
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
    $script:PsaToReviewdogScript = Join-Path $script:TestRepoRoot '.github' 'scripts' 'psa_to_reviewdog.ps1'
    $ConfirmPreference = 'None'
}

Describe 'psa_to_reviewdog.ps1 execution' {
    It 'Fails when the PSScriptAnalyzer report path does not exist' {
        $missingReport = Join-Path (New-TestTempDirectory -Prefix 'PsaReviewdogMissing') 'missing-report.json'
        try {
            $result = Invoke-TestScriptFile -ScriptPath $script:PsaToReviewdogScript -ArgumentList @(
                '-ReportPath', $missingReport
            )

            $result.ExitCode | Should -Be 1
            $result.Output | Should -Match 'Report not found'
        }
        finally {
            $parent = Split-Path -Parent $missingReport
            if (Test-Path -LiteralPath $parent) {
                Remove-Item -LiteralPath $parent -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }

    It 'Converts a PSScriptAnalyzer JSON report into reviewdog rdjson output' {
        $workDir = New-TestTempDirectory -Prefix 'PsaReviewdogConvert'
        $reportPath = Join-Path $workDir 'psa-report.json'
        $outputPath = Join-Path $workDir 'psa_for_reviewdog.rdjson'
        try {
            @(
                [pscustomobject]@{
                    FilePath = 'scripts/test.ps1'
                    RuleName = 'PSUseApprovedVerbs'
                    Severity = 'Warning'
                    Message  = 'Test diagnostic message'
                    Line     = 4
                    Column   = 10
                }
            ) | ConvertTo-Json | Set-Content -LiteralPath $reportPath -Encoding UTF8

            Push-Location $workDir
            try {
                $result = Invoke-TestScriptFile -ScriptPath $script:PsaToReviewdogScript -ArgumentList @(
                    '-ReportPath', $reportPath
                )

                $result.ExitCode | Should -Be 0
                $result.Output | Should -Match 'Converted 1 items'
                Test-Path -LiteralPath $outputPath | Should -BeTrue
                $converted = Get-Content -LiteralPath $outputPath -Raw | ConvertFrom-Json
                $converted.diagnostics.Count | Should -Be 1
                $converted.diagnostics[0].severity | Should -Be 'WARNING'
            }
            finally {
                Pop-Location
            }
        }
        finally {
            if (Test-Path -LiteralPath $workDir) {
                Remove-Item -LiteralPath $workDir -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }

    It 'Converts an empty PSScriptAnalyzer report into reviewdog output with zero diagnostics' {
        $workDir = New-TestTempDirectory -Prefix 'PsaReviewdogEmpty'
        $reportPath = Join-Path $workDir 'empty-report.json'
        try {
            '[]' | Set-Content -LiteralPath $reportPath -Encoding UTF8

            Push-Location $workDir
            try {
                $result = Invoke-TestScriptFile -ScriptPath $script:PsaToReviewdogScript -ArgumentList @(
                    '-ReportPath', $reportPath
                )

                $result.ExitCode | Should -Be 0
                $result.Output | Should -Match 'Converted 0 items'
                $converted = Get-Content -LiteralPath (Join-Path $workDir 'psa_for_reviewdog.rdjson') -Raw | ConvertFrom-Json
                $converted.diagnostics.Count | Should -Be 0
            }
            finally {
                Pop-Location
            }
        }
        finally {
            if (Test-Path -LiteralPath $workDir) {
                Remove-Item -LiteralPath $workDir -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }
}
