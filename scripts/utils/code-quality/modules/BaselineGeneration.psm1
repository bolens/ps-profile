<#
scripts/utils/code-quality/modules/BaselineGeneration.psm1

.SYNOPSIS
    Performance baseline generation utilities.

.DESCRIPTION
    Provides functions for generating performance baselines from test results.
#>

# Import Logging module for Write-ScriptMessage
$loggingModulePath = Join-Path (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)))) 'lib' 'Logging.psm1'
if (Test-Path $loggingModulePath) {
    Import-Module $loggingModulePath -DisableNameChecking -ErrorAction SilentlyContinue
}

# Import TestEnvironment module for Get-TestEnvironment
$testEnvironmentModulePath = Join-Path $PSScriptRoot 'TestEnvironment.psm1'
if (Test-Path $testEnvironmentModulePath) {
    Import-Module $testEnvironmentModulePath -DisableNameChecking -ErrorAction SilentlyContinue
}

# Try to import JsonUtilities module from scripts/lib (optional)
$jsonUtilitiesModulePath = Join-Path (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)))) 'lib' 'JsonUtilities.psm1'
if (Test-Path $jsonUtilitiesModulePath) {
    Import-Module $jsonUtilitiesModulePath -DisableNameChecking -ErrorAction SilentlyContinue
}

<#
.SYNOPSIS
    Generates a performance baseline from test results.

.DESCRIPTION
    Creates a baseline file containing performance metrics for future comparisons.
    Used to detect performance regressions over time.

.PARAMETER TestResult
    The Pester test result object.

.PARAMETER PerformanceData
    Performance metrics from test execution.

.PARAMETER OutputPath
    Path to save the baseline file. Defaults to 'performance-baseline.json'.

.OUTPUTS
    Baseline data object
#>
function New-PerformanceBaseline {
    param(
        [Parameter(Mandatory)]
        $TestResult,

        $PerformanceData,

        [string]$OutputPath = 'performance-baseline.json'
    )

    $baseline = @{
        GeneratedAt = Get-Date
        TestSummary = @{
            TotalTests   = $TestResult.TotalCount
            PassedTests  = $TestResult.PassedCount
            FailedTests  = $TestResult.FailedCount
            SkippedTests = $TestResult.SkippedCount
            Duration     = if ($TestResult.Time) { $TestResult.Time } else { $TestResult.Duration }
        }
        Performance = if ($PerformanceData) {
            # Simplify performance data to avoid deep nesting issues
            @{
                Duration        = $PerformanceData.Duration
                PeakMemoryMB    = $PerformanceData.PeakMemoryMB
                AverageMemoryMB = $PerformanceData.AverageMemoryMB
                CPUUsage        = $PerformanceData.CPUUsage
            }
        }
        else { $null }
        TestMetrics = @{}  # Skip detailed test metrics to avoid serialization issues
        Environment = Get-TestEnvironment
    }

    # Skip collecting individual test metrics to avoid JSON serialization depth issues
    # This provides a basic baseline for overall performance tracking

    # Save baseline to file with custom JSON creation to avoid depth issues
    $jsonObject = @{
        GeneratedAt = $baseline.GeneratedAt.ToString('o')  # ISO 8601 format
        TestSummary = @{
            TotalTests   = $baseline.TestSummary.TotalTests
            PassedTests  = $baseline.TestSummary.PassedTests
            FailedTests  = $baseline.TestSummary.FailedTests
            SkippedTests = $baseline.TestSummary.SkippedTests
            Duration     = $baseline.TestSummary.Duration.ToString()
        }
        Performance = if ($baseline.Performance) {
            @{
                Duration        = $baseline.Performance.Duration.ToString()
                PeakMemoryMB    = $baseline.Performance.PeakMemoryMB
                AverageMemoryMB = $baseline.Performance.AverageMemoryMB
                CPUUsage        = $baseline.Performance.CPUUsage
            }
        }
        else { $null }
        TestMetrics = @{}  # Empty for now to avoid serialization issues
        Environment = @{
            IsCI              = $baseline.Environment.IsCI
            CIProvider        = $baseline.Environment.CIProvider
            IsContainer       = $baseline.Environment.IsContainer
            HasDocker         = [bool]$baseline.Environment.HasDocker
            HasPodman         = [bool]$baseline.Environment.HasPodman
            HasGit            = [bool]$baseline.Environment.HasGit
            PowerShellVersion = if ($baseline.Environment.PowerShellVersion) { $baseline.Environment.PowerShellVersion.ToString() } else { 'Unknown' }
            OS                = $baseline.Environment.OS
            Platform          = if ($baseline.Environment.Platform) { $baseline.Environment.Platform.ToString() } else { 'Unknown' }
            AvailableMemoryGB = $baseline.Environment.AvailableMemoryGB
            ProcessorCount    = $baseline.Environment.ProcessorCount
        }
    }

    if (Get-Command Write-JsonFile -ErrorAction SilentlyContinue) {
        Write-JsonFile -Path $OutputPath -InputObject $jsonObject -Depth 10 -EnsureDirectory
    }
    else {
        $jsonObject | ConvertTo-Json -Depth 10 | Out-File -FilePath $OutputPath -Encoding UTF8
    }

    if (Get-Command Write-ScriptMessage -ErrorAction SilentlyContinue) {
        Write-ScriptMessage -Message "Performance baseline saved to: $OutputPath"
    }

    return $baseline
}

Export-ModuleMember -Function New-PerformanceBaseline

