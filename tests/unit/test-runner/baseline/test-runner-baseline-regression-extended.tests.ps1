<#
tests/unit/test-runner-baseline-regression-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for BaselineComparison regression helpers.
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

    $script:TempDir = New-TestTempDirectory -Prefix 'BaselineRegressionExtended'
}

AfterAll {
    if ($script:TempDir -and (Test-Path -LiteralPath $script:TempDir)) {
        Remove-Item -LiteralPath $script:TempDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Describe 'BaselineComparison extended scenarios' {
    Context 'Compare-PerformanceBaseline' {
        It 'Detects duration regressions above the threshold' {
            $baselinePath = Join-Path $script:TempDir 'baseline.json'
            @'
{
  "GeneratedAt": "2024-01-01T00:00:00Z",
  "TestSummary": {
    "TotalTests": 2,
    "Duration": "00:00:10"
  },
  "TestMetrics": {}
}
'@ | Set-Content -LiteralPath $baselinePath -Encoding UTF8

            $result = Compare-PerformanceBaseline -TestResult @{
                TotalCount = 2
                Time       = [TimeSpan]::FromSeconds(15)
            } -BaselinePath $baselinePath -Threshold 5

            $result.Success | Should -Be $true
            $result.OverallChange.DurationChange.IsRegression | Should -Be $true
            $result.OverallChange.DurationChange.IsImprovement | Should -Be $false
        }

        It 'Returns failure details for invalid baseline JSON' {
            $invalidPath = Join-Path $script:TempDir 'invalid-baseline.json'
            Set-Content -LiteralPath $invalidPath -Value '{ not valid json' -Encoding UTF8

            $result = Compare-PerformanceBaseline -TestResult @{
                TotalCount = 1
                Time       = [TimeSpan]::FromSeconds(1)
            } -BaselinePath $invalidPath

            $result.Success | Should -Be $false
            $result.Message | Should -Match 'Failed to load baseline'
        }

        It 'Records per-test regressions when metrics exceed the threshold' {
            $baselinePath = Join-Path $script:TempDir 'per-test-baseline.json'
            @{
                GeneratedAt = '2024-01-02T00:00:00Z'
                TestSummary = @{
                    TotalTests = 1
                    Duration   = '00:00:05'
                }
                TestMetrics = @{
                    SlowTest = @{
                        Duration = '00:00:01'
                    }
                }
            } | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $baselinePath -Encoding UTF8

            $result = Compare-PerformanceBaseline -TestResult @{
                TotalCount  = 1
                Time        = [TimeSpan]::FromSeconds(5)
                PassedTests = @(
                    [PSCustomObject]@{
                        Name     = 'SlowTest'
                        File     = 'slow.tests.ps1'
                        Duration = [TimeSpan]::FromSeconds(3)
                    }
                )
            } -BaselinePath $baselinePath -Threshold 5

            @($result.Regressions).Count | Should -BeGreaterThan 0
            $result.Regressions[0].TestName | Should -Be 'SlowTest'
        }
    }

    Context 'New-PerformanceRegressionReport' {
        It 'Lists individual regressions in the report text' {
            $comparison = @{
                Success       = $true
                BaselineDate  = '2024-01-01T00:00:00Z'
                CurrentDate   = Get-Date
                Regressions   = @(
                    @{
                        TestName      = 'RegressionSample'
                        File          = 'sample.tests.ps1'
                        ChangePercent = 25
                    }
                )
                Improvements  = @()
                OverallChange = @{ TestCountChange = 0 }
            }

            $report = New-PerformanceRegressionReport -Comparison $comparison -Threshold 5
            $report | Should -Match 'RegressionSample'
        }

        It 'Mentions improvements when duration decreased materially' {
            $comparison = @{
                Success       = $true
                BaselineDate  = '2024-01-01T00:00:00Z'
                CurrentDate   = Get-Date
                Regressions   = @()
                Improvements  = @()
                OverallChange = @{
                    TestCountChange = 0
                    DurationChange  = @{
                        Baseline      = [TimeSpan]::FromSeconds(10)
                        Current       = [TimeSpan]::FromSeconds(6)
                        ChangePercent = -40
                        IsRegression  = $false
                        IsImprovement = $true
                    }
                }
            }

            $report = New-PerformanceRegressionReport -Comparison $comparison -Threshold 5
            $report | Should -Match 'improved|Improvement|decreased'
        }
    }
}
