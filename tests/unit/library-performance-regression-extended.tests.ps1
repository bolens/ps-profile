<#
tests/unit/library-performance-regression-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for Test-PerformanceRegression metric comparison edge cases.
#>

BeforeAll {
    . (Join-Path $PSScriptRoot '..\TestSupport.ps1')

    $script:LibPath = Get-TestPath -RelativePath 'scripts\lib' -StartPath $PSScriptRoot -EnsureExists
    Import-Module (Join-Path $script:LibPath 'utilities' 'JsonUtilities.psm1') -DisableNameChecking -Force
    Import-Module (Join-Path $script:LibPath 'performance' 'PerformanceRegression.psm1') -DisableNameChecking -Force

    $script:TempDir = New-TestTempDirectory -Prefix 'PerformanceRegressionExtended'
    $script:BaselineFile = Join-Path $script:TempDir 'baseline.json'
    @{
        DurationMs = 1000
        MemoryMB   = 50
    } | ConvertTo-Json | Set-Content -LiteralPath $script:BaselineFile -Encoding UTF8
}

AfterAll {
    Remove-Module PerformanceRegression, JsonUtilities -ErrorAction SilentlyContinue -Force

    if ($script:TempDir -and (Test-Path -LiteralPath $script:TempDir)) {
        Remove-Item -LiteralPath $script:TempDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Describe 'PerformanceRegression extended scenarios' {
    Context 'Test-PerformanceRegression' {
        It 'Detects memory regressions independently of duration' {
            $result = Test-PerformanceRegression -CurrentMetrics @{
                DurationMs = 900
                MemoryMB   = 120
            } -BaselineFile $script:BaselineFile

            $result.RegressionDetected | Should -Be $true
            @($result.Details | Where-Object { $_.Metric -eq 'MemoryMB' }).Count | Should -Be 1
        }

        It 'Reports no regression when metrics match the baseline exactly' {
            $result = Test-PerformanceRegression -CurrentMetrics @{
                DurationMs = 1000
                MemoryMB   = 50
            } -BaselineFile $script:BaselineFile

            $result.RegressionDetected | Should -Be $false
            $result.Ratio | Should -Be 1
        }

        It 'Ignores metrics that are absent from the baseline file' {
            $result = Test-PerformanceRegression -CurrentMetrics @{
                CpuPercent = 95
            } -BaselineFile $script:BaselineFile

            $result.RegressionDetected | Should -Be $false
            @($result.Details).Count | Should -Be 0
        }

        It 'Returns baseline load errors for invalid JSON files' {
            $invalidBaseline = Join-Path $script:TempDir 'invalid-baseline.json'
            Set-Content -LiteralPath $invalidBaseline -Value '{ not json' -Encoding UTF8

            $result = Test-PerformanceRegression -CurrentMetrics @{ DurationMs = 1000 } -BaselineFile $invalidBaseline -WarningAction SilentlyContinue

            $result.RegressionDetected | Should -Be $false
            $result.Message | Should -Match 'Error loading baseline'
        }

        It 'Includes the operation name in successful comparisons' {
            $result = Test-PerformanceRegression -CurrentMetrics @{ DurationMs = 800 } -BaselineFile $script:BaselineFile -OperationName 'StartupBenchmark'

            $result.OperationName | Should -Be 'StartupBenchmark'
        }
    }
}
