<#
tests/unit/test-runner-baseline-comparison-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for BaselineComparison edge cases.
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

    $script:TempDir = New-TestTempDirectory -Prefix 'BaselineComparisonExtended'
}

AfterAll {
    if ($script:TempDir -and (Test-Path -LiteralPath $script:TempDir)) {
        Remove-Item -LiteralPath $script:TempDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Describe 'BaselineComparison extended scenarios' {
    Context 'Compare-PerformanceBaseline' {
        It 'Returns failure when baseline JSON is invalid' {
            $badPath = Join-Path $script:TempDir 'invalid-baseline.json'
            Set-Content -LiteralPath $badPath -Value '{ not valid json' -Encoding UTF8

            $result = Compare-PerformanceBaseline -TestResult @{
                TotalCount = 1
                Time       = [TimeSpan]::FromSeconds(1)
            } -BaselinePath $badPath

            $result.Success | Should -Be $false
            $result.Message | Should -Match 'Failed to load baseline file'
        }

        It 'Records improvements when tests run faster than baseline' {
            $baselinePath = Join-Path $script:TempDir 'fast-baseline.json'
            @{
                GeneratedAt = (Get-Date).AddDays(-1).ToString('o')
                TestSummary = @{
                    TotalTests = 1
                    Duration   = '00:00:10'
                }
                TestMetrics = @{
                    'FastTest' = @{ Duration = '00:00:10' }
                }
            } | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $baselinePath -Encoding UTF8

            $result = Compare-PerformanceBaseline -TestResult @{
                TotalCount  = 1
                Time        = [TimeSpan]::FromSeconds(5)
                PassedTests = @(
                    [PSCustomObject]@{ Name = 'FastTest'; Duration = [TimeSpan]::FromSeconds(4); File = 'fast.ps1' }
                )
            } -BaselinePath $baselinePath -Threshold 5

            $result.Success | Should -Be $true
            @($result.Improvements).Count | Should -BeGreaterThan 0
            $result.OverallChange.DurationChange.IsImprovement | Should -Be $true
        }
    }

    Context 'New-PerformanceRegressionReport' {
        It 'Reports no significant changes when within threshold' {
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
                        Current       = [TimeSpan]::FromSeconds(5.1)
                        ChangePercent = 2
                        IsRegression  = $false
                        IsImprovement = $false
                    }
                }
            }

            $report = New-PerformanceRegressionReport -Comparison $comparison -Threshold 5

            $report | Should -Match 'No significant performance changes detected'
            $report | Should -Not -Match 'WARNING: Duration increased'
        }

        It 'Lists per-test improvements in report text' {
            $comparison = @{
                Success       = $true
                BaselineDate  = '2024-01-01T00:00:00Z'
                CurrentDate   = Get-Date
                Regressions   = @()
                Improvements  = @(
                    @{
                        TestName      = 'OptimizedTest'
                        File          = 'tests/unit/optimized.tests.ps1'
                        Baseline      = [TimeSpan]::FromSeconds(2)
                        Current       = [TimeSpan]::FromSeconds(1)
                        ChangePercent = -50
                    }
                )
                OverallChange = @{ TestCountChange = 0 }
            }

            $report = New-PerformanceRegressionReport -Comparison $comparison

            $report | Should -Match 'Performance Improvements'
            $report | Should -Match 'OptimizedTest'
        }
    }
}
