<#
tests/LibraryFunctions.tests.ps1

Tests for library module functions that are not yet covered by other test files.
#>

BeforeAll {
    # Import the Common module
    $commonModulePath = Join-Path $PSScriptRoot '..' 'scripts' 'lib' 'Common.psm1'
    Import-Module $commonModulePath -DisableNameChecking -ErrorAction Stop

    # Get repository root
    $script:RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
    $script:TestTempDir = Join-Path $env:TEMP "PowerShellProfileLibraryTests_$(New-Guid)"

    # Create test directory
    New-Item -ItemType Directory -Path $script:TestTempDir -Force | Out-Null
}

AfterAll {
    # Cleanup test directory
    if (Test-Path $script:TestTempDir) {
        Remove-Item -Path $script:TestTempDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Describe 'CodeAnalysis Module - Additional Functions' {
    Context 'Get-TestCoverage' {
        It 'Handles missing coverage file gracefully' {
            $nonExistentFile = Join-Path $script:TestTempDir 'nonexistent-coverage.xml'
            $result = Get-TestCoverage -CoverageXmlPath $nonExistentFile
            $result.CoveragePercent | Should -Be 0
            $result.TotalLines | Should -Be 0
            $result.FileCount | Should -Be 0
        }

        It 'Parses valid coverage XML structure' {
            # Create a minimal valid coverage XML
            $coverageXml = @'
<?xml version="1.0" encoding="utf-8"?>
<Coverage>
    <Module ModulePath="test.ps1">
        <Function FunctionName="Test-Function">
            <Line Number="1" Covered="true" />
            <Line Number="2" Covered="true" />
            <Line Number="3" Covered="false" />
        </Function>
    </Module>
</Coverage>
'@
            $coverageFile = Join-Path $script:TestTempDir 'coverage.xml'
            $coverageXml | Set-Content -Path $coverageFile -Encoding UTF8

            $result = Get-TestCoverage -CoverageXmlPath $coverageFile
            $result.TotalLines | Should -Be 3
            $result.CoveredLines | Should -Be 2
            $result.UncoveredLines | Should -Be 1
            $result.CoveragePercent | Should -BeGreaterThan 0
            $result.FileCount | Should -BeGreaterThan 0
        }
    }

    Context 'Get-CodeQualityScore' {
        It 'Calculates quality score for valid metrics' {
            $metrics = [PSCustomObject]@{
                TotalLines               = 1000
                TotalFunctions           = 50
                TotalComplexity          = 200
                DuplicateFunctions       = 0
                AverageLinesPerFile      = 50
                AverageComplexityPerFile = 10
            }

            $result = Get-CodeQualityScore -CodeMetrics $metrics
            $result | Should -Not -BeNullOrEmpty
            $result.Score | Should -BeGreaterOrEqual 0
            $result.Score | Should -BeLessOrEqual 100
        }
    }

    Context 'Get-CodeSimilarity' {
        It 'Detects similar code patterns' {
            $testDir = Join-Path $script:TestTempDir 'similarity-test'
            New-Item -ItemType Directory -Path $testDir -Force | Out-Null

            # Create two similar scripts
            $script1 = @'
function Test-Function {
    param($Name)
    Write-Output "Hello $Name"
}
'@
            $script2 = @'
function Test-Function {
    param($Name)
    Write-Output "Hello $Name"
}
'@

            $script1 | Set-Content -Path (Join-Path $testDir 'script1.ps1') -Encoding UTF8
            $script2 | Set-Content -Path (Join-Path $testDir 'script2.ps1') -Encoding UTF8

            $result = Get-CodeSimilarity -Path $testDir -MinSimilarity 0.5
            $result | Should -Not -BeNullOrEmpty
            ($result -is [System.Array]) | Should -BeTrue
        }
    }

    Context 'Get-StringSimilarity' {
        It 'Calculates similarity between strings' {
            $result = Get-StringSimilarity -String1 "hello world" -String2 "hello world"
            $result | Should -BeGreaterThan 0.9

            $result2 = Get-StringSimilarity -String1 "hello" -String2 "world"
            $result2 | Should -BeLessThan 0.5
        }
    }
}

Describe 'Metrics Module Functions' {
    Context 'Get-MetricsTrend' {
        It 'Handles insufficient data gracefully' {
            $emptyData = @()
            $result = Get-MetricsTrend -HistoricalData $emptyData -MetricName "TotalFiles"
            $result.TrendDirection | Should -Be "InsufficientData"
            $result.DataPoints | Should -Be 0
            $result.Message | Should -Match "Need at least 2 data points"
        }

        It 'Calculates trend for valid data' {
            $historicalData = @(
                @{ Timestamp = "2024-01-01T00:00:00Z"; TotalFiles = 10 },
                @{ Timestamp = "2024-01-02T00:00:00Z"; TotalFiles = 15 },
                @{ Timestamp = "2024-01-03T00:00:00Z"; TotalFiles = 20 }
            )

            $result = Get-MetricsTrend -HistoricalData $historicalData -MetricName "TotalFiles"
            $result.TrendDirection | Should -Not -Be "InsufficientData"
            $result.DataPoints | Should -Be 3
            $result.GrowthRate | Should -BeGreaterThan 0
        }

        It 'Handles nested metric paths' {
            $historicalData = @(
                @{ Timestamp = "2024-01-01T00:00:00Z"; CodeMetrics = @{ TotalFiles = 10 } },
                @{ Timestamp = "2024-01-02T00:00:00Z"; CodeMetrics = @{ TotalFiles = 15 } }
            )

            $result = Get-MetricsTrend -HistoricalData $historicalData -MetricName "CodeMetrics.TotalFiles"
            $result.DataPoints | Should -BeGreaterThan 0
        }
    }

    Context 'Get-HistoricalMetrics' {
        It 'Returns empty array for non-existent directory' {
            $nonExistentPath = Join-Path $script:TestTempDir 'nonexistent-history'
            $result = Get-HistoricalMetrics -HistoryPath $nonExistentPath
            $result | Should -BeNullOrEmpty
        }

        It 'Loads historical metrics from JSON files' {
            $historyDir = Join-Path $script:TestTempDir 'history'
            New-Item -ItemType Directory -Path $historyDir -Force | Out-Null

            # Create a test metrics file
            $metrics = @{
                Timestamp  = "2024-01-01T00:00:00Z"
                TotalFiles = 10
            } | ConvertTo-Json

            $metricsFile = Join-Path $historyDir 'metrics-20240101-000000.json'
            $metrics | Set-Content -Path $metricsFile -Encoding UTF8

            $result = Get-HistoricalMetrics -HistoryPath $historyDir
            $result.Count | Should -BeGreaterThan 0
            $result[0].TotalFiles | Should -Be 10
        }

        It 'Respects Limit parameter' {
            $historyDir = Join-Path $script:TestTempDir 'history-limit'
            New-Item -ItemType Directory -Path $historyDir -Force | Out-Null

            # Create multiple metrics files
            1..5 | ForEach-Object {
                $metrics = @{
                    Timestamp  = "2024-01-0$_`T00:00:00Z"
                    TotalFiles = $_
                } | ConvertTo-Json

                $metricsFile = Join-Path $historyDir "metrics-2024010$_`-000000.json"
                $metrics | Set-Content -Path $metricsFile -Encoding UTF8
            }

            $result = Get-HistoricalMetrics -HistoryPath $historyDir -Limit 3
            $result.Count | Should -BeLessOrEqual 3
        }
    }

    Context 'Save-MetricsSnapshot' {
        It 'Saves metrics snapshot to specified path' {
            $snapshotDir = Join-Path $script:TestTempDir 'snapshots'

            $snapshotPath = Save-MetricsSnapshot -OutputPath $snapshotDir
            Test-Path $snapshotPath | Should -Be $true
            $snapshotPath | Should -Match 'metrics-\d{8}-\d{6}\.json'

            $snapshotContent = Get-Content -Path $snapshotPath -Raw | ConvertFrom-Json
            $snapshotContent.Timestamp | Should -Not -BeNullOrEmpty
        }

        It 'Includes code metrics when specified' {
            $snapshotDir = Join-Path $script:TestTempDir 'snapshots-code'
            $codeMetricsFile = Join-Path $script:RepoRoot 'scripts' 'data' 'code-metrics.json'

            if (Test-Path $codeMetricsFile) {
                $snapshotPath = Save-MetricsSnapshot -OutputPath $snapshotDir -IncludeCodeMetrics
                $snapshotContent = Get-Content -Path $snapshotPath -Raw | ConvertFrom-Json
                $snapshotContent.CodeMetrics | Should -Not -BeNullOrEmpty
            }
            else {
                Set-ItResult -Skipped -Because "code-metrics.json not found"
            }
        }
    }
}

Describe 'Performance Module - Get-AggregatedMetrics' {
    Context 'Aggregation Calculations' {
        It 'Handles empty metrics array' {
            $result = Get-AggregatedMetrics -Metrics @() -OperationName "Test"
            $result.Count | Should -Be 0
            $result.AverageDurationMs | Should -Be 0
            $result.SuccessRate | Should -Be 0
        }

        It 'Aggregates multiple metrics correctly' {
            $metrics = @(
                @{ DurationMs = 100; Success = $true },
                @{ DurationMs = 200; Success = $true },
                @{ DurationMs = 150; Success = $false }
            )

            $result = Get-AggregatedMetrics -Metrics $metrics -OperationName "TestOp"
            $result.Count | Should -Be 3
            $result.AverageDurationMs | Should -BeGreaterThan 0
            $result.SuccessCount | Should -Be 2
            $result.FailureCount | Should -Be 1
            $result.SuccessRate | Should -BeGreaterThan 0
        }

        It 'Calculates min and max durations' {
            $metrics = @(
                @{ DurationMs = 50; Success = $true },
                @{ DurationMs = 200; Success = $true },
                @{ DurationMs = 100; Success = $true }
            )

            $result = Get-AggregatedMetrics -Metrics $metrics -OperationName "TestOp"
            $result.MinDurationMs | Should -Be 50
            $result.MaxDurationMs | Should -Be 200
        }
    }
}

Describe 'DataFile Module - Import-CachedPowerShellDataFile' {
    Context 'Caching Behavior' {
        It 'Throws error for non-existent file' {
            $nonExistentFile = Join-Path $script:TestTempDir 'nonexistent.psd1'
            { Import-CachedPowerShellDataFile -Path $nonExistentFile } | Should -Throw
        }

        It 'Imports valid PowerShell data file' {
            # Create a test .psd1 file
            $testData = @'
@{
    Name = "TestModule"
    Version = "1.0.0"
    Functions = @("Test-Function1", "Test-Function2")
}
'@
            $testFile = Join-Path $script:TestTempDir 'test.psd1'
            $testData | Set-Content -Path $testFile -Encoding UTF8

            $result = Import-CachedPowerShellDataFile -Path $testFile
            $result | Should -Not -BeNullOrEmpty
            $result.Name | Should -Be "TestModule"
            $result.Version | Should -Be "1.0.0"
        }

        It 'Uses cache on second call' {
            $testData = @'
@{
    TestValue = "cached"
}
'@
            $testFile = Join-Path $script:TestTempDir 'cache-test.psd1'
            $testData | Set-Content -Path $testFile -Encoding UTF8

            $result1 = Import-CachedPowerShellDataFile -Path $testFile
            $result2 = Import-CachedPowerShellDataFile -Path $testFile
            $result1.TestValue | Should -Be $result2.TestValue
        }
    }
}

Describe 'Module Module Functions' {
    Context 'Import-RequiredModule' {
        It 'Imports existing module successfully' {
            # Test with a module that should exist (Pester is used in tests)
            if (Get-Module -ListAvailable -Name 'Pester' -ErrorAction SilentlyContinue) {
                { Import-RequiredModule -ModuleName 'Pester' -Force } | Should -Not -Throw
            }
            else {
                Set-ItResult -Skipped -Because "Pester module not available"
            }
        }

        It 'Throws error for non-existent module' {
            $nonExistentModule = "NonExistentModule_$(New-Guid)"
            { Import-RequiredModule -ModuleName $nonExistentModule } | Should -Throw
        }
    }

    Context 'Ensure-ModuleAvailable' {
        It 'Ensures module is available when already installed' {
            if (Get-Module -ListAvailable -Name 'Pester' -ErrorAction SilentlyContinue) {
                { Ensure-ModuleAvailable -ModuleName 'Pester' } | Should -Not -Throw
            }
            else {
                Set-ItResult -Skipped -Because "Pester module not available"
            }
        }
    }
}

Describe 'Path Module - Get-CommonModulePath' {
    Context 'Path Resolution' {
        It 'Returns valid path to Common.psm1' {
            $result = Get-CommonModulePath -ScriptPath $PSScriptRoot
            $result | Should -Not -BeNullOrEmpty
            $result | Should -Match 'Common\.psm1$'
        }

        It 'Resolves path correctly for scripts/utils location' {
            $utilsScriptPath = Join-Path $script:RepoRoot 'scripts' 'utils' 'test.ps1'
            $result = Get-CommonModulePath -ScriptPath $utilsScriptPath
            Test-Path $result | Should -Be $true
        }
    }
}

Describe 'Platform Module - Get-Platform' {
    Context 'Platform Detection' {
        It 'Returns platform information object' {
            $result = Get-Platform
            $result | Should -Not -BeNullOrEmpty
            $result.PSObject.Properties.Name | Should -Contain 'Name'
            $result.PSObject.Properties.Name | Should -Contain 'IsWindows'
            $result.PSObject.Properties.Name | Should -Contain 'IsLinux'
            $result.PSObject.Properties.Name | Should -Contain 'IsMacOS'
        }

        It 'Platform flags are mutually exclusive' {
            $platform = Get-Platform
            $trueCount = @($platform.IsWindows, $platform.IsLinux, $platform.IsMacOS) | Where-Object { $_ -eq $true } | Measure-Object | Select-Object -ExpandProperty Count
            $trueCount | Should -BeLessOrEqual 1
        }
    }
}

Describe 'FileSystem Module - Test-PathParameter' {
    Context 'Path Parameter Validation' {
        It 'Validates path parameter exists' {
            $testFile = Join-Path $script:TestTempDir 'test.txt'
            New-Item -ItemType File -Path $testFile -Force | Out-Null

            { Test-PathParameter -Path $testFile -PathType 'File' } | Should -Not -Throw
        }

        It 'Throws error for non-existent path' {
            $nonExistentPath = Join-Path $script:TestTempDir 'nonexistent.txt'
            { Test-PathParameter -Path $nonExistentPath -PathType 'File' } | Should -Throw
        }

        It 'Throws error for wrong path type' {
            $testDir = Join-Path $script:TestTempDir 'testdir'
            New-Item -ItemType Directory -Path $testDir -Force | Out-Null

            { Test-PathParameter -Path $testDir -PathType 'File' } | Should -Throw
        }
    }
}


