<#
tests/unit/test-runner-baseline-regression.tests.ps1

.SYNOPSIS
    Unit tests for BaselineComparison regression reporting.
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
    $modulePath = Join-Path (Get-TestRepoRoot -StartPath $PSScriptRoot) 'scripts/utils/code-quality/modules'
    Import-Module (Join-Path (Get-TestRepoRoot -StartPath $PSScriptRoot) 'scripts/lib/core/Logging.psm1') -DisableNameChecking -Force -Global
    Import-Module (Join-Path $modulePath 'BaselineComparison.psm1') -Force -Global

    $script:TempDir = New-TestTempDirectory -Prefix 'BaselineRegressionTests'
}

AfterAll {
    if ($script:TempDir -and (Test-Path -LiteralPath $script:TempDir)) {
        Remove-Item -LiteralPath $script:TempDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Describe 'BaselineComparison Module' {
    Context 'Compare-PerformanceBaseline' {
        It 'Returns failure details when baseline file is missing' {
            $missing = Join-Path $script:TempDir 'missing-baseline.json'
            $result = Compare-PerformanceBaseline -TestResult @{
                TotalCount = 1
                Time       = [TimeSpan]::FromSeconds(1)
            } -BaselinePath $missing

            $result.Success | Should -Be $false
            $result.Message | Should -Match 'Baseline file not found'
        }
    }

    Context 'New-PerformanceRegressionReport' {
        It 'Reports failure message when comparison was unsuccessful' {
            $report = New-PerformanceRegressionReport -Comparison @{
                Success = $false
                Message = 'Baseline file not found'
            }

            $report | Should -Match 'Performance regression analysis failed'
            $report | Should -Match 'Baseline file not found'
        }

        It 'Highlights duration regressions in report text' {
            $comparison = @{
                Success       = $true
                BaselineDate  = '2024-01-01T00:00:00Z'
                CurrentDate   = Get-Date
                Regressions   = @()
                Improvements  = @()
                OverallChange = @{
                    TestCountChange = 0
                    DurationChange  = @{
                        Baseline      = [TimeSpan]::FromSeconds(5)
                        Current       = [TimeSpan]::FromSeconds(7)
                        ChangePercent = 40
                        IsRegression  = $true
                        IsImprovement = $false
                    }
                }
            }

            $report = New-PerformanceRegressionReport -Comparison $comparison -Threshold 5

            $report | Should -Match 'Performance Regression Report'
            $report | Should -Match 'WARNING: Duration increased'
        }

        It 'Writes report to disk when OutputPath is provided' {
            $comparison = @{
                Success       = $true
                BaselineDate  = '2024-01-01T00:00:00Z'
                CurrentDate   = Get-Date
                Regressions   = @()
                Improvements  = @()
                OverallChange = @{ TestCountChange = 0 }
            }

            $outputPath = Join-Path $script:TempDir 'regression-report.txt'
            $null = New-PerformanceRegressionReport -Comparison $comparison -OutputPath $outputPath

            Test-Path -LiteralPath $outputPath | Should -Be $true
            (Get-Content -LiteralPath $outputPath -Raw) | Should -Match 'Performance Regression Report'
        }
    }
}
