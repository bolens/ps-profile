<#
scripts/utils/code-quality/modules/BaselineComparison.psm1

.SYNOPSIS
    Performance baseline comparison utilities.

.DESCRIPTION
    Provides functions for comparing test results against baselines and generating regression reports.
#>

# Import Logging module for Write-ScriptMessage
$loggingModulePath = Join-Path (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)))) 'lib' 'core' 'Logging.psm1'
if ($loggingModulePath -and -not [string]::IsNullOrWhiteSpace($loggingModulePath) -and (Test-Path -LiteralPath $loggingModulePath)) {
    try {
        Import-Module $loggingModulePath -DisableNameChecking -ErrorAction Stop
    }
    catch {
        Write-Verbose "Failed to import Logging module: $($_.Exception.Message). Logging features may be limited."
    }
}

# Try to import JsonUtilities module from scripts/lib (optional)
$jsonUtilitiesModulePath = Join-Path (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)))) 'lib' 'utilities' 'JsonUtilities.psm1'
if ($jsonUtilitiesModulePath -and -not [string]::IsNullOrWhiteSpace($jsonUtilitiesModulePath) -and (Test-Path -LiteralPath $jsonUtilitiesModulePath)) {
    try {
        Import-Module $jsonUtilitiesModulePath -DisableNameChecking -ErrorAction Stop
    }
    catch {
        Write-Verbose "Failed to import JsonUtilities module: $($_.Exception.Message). JSON operations may be limited."
    }
}

<#
.SYNOPSIS
    Compares current test results against a performance baseline.

.DESCRIPTION
    Loads a baseline file and compares current performance metrics
    to detect regressions or improvements.

.PARAMETER TestResult
    The current Pester test result object.

.PARAMETER PerformanceData
    Current performance metrics.

.PARAMETER BaselinePath
    Path to the baseline file.

.PARAMETER Threshold
    Acceptable deviation percentage from baseline (0-100). Defaults to 5%.

.OUTPUTS
    Baseline comparison results
#>
function Compare-PerformanceBaseline {
    param(
        [Parameter(Mandatory)]
        $TestResult,

        $PerformanceData,

        [string]$BaselinePath = 'performance-baseline.json',

        [ValidateRange(0, 100)]
        [int]$Threshold = 5
    )

    if ($BaselinePath -and -not [string]::IsNullOrWhiteSpace($BaselinePath) -and -not (Test-Path -LiteralPath $BaselinePath)) {
        Write-ScriptMessage -Message "Baseline file not found: $BaselinePath" -LogLevel 'Warning'
        return @{
            Success       = $false
            Message       = "Baseline file not found"
            Regressions   = @()
            Improvements  = @()
            OverallChange = $null
        }
    }

    try {
        if (Get-Command Read-JsonFile -ErrorAction SilentlyContinue) {
            $baseline = Read-JsonFile -Path $BaselinePath -ErrorAction SilentlyContinue
        }
        else {
            try {
                $baselineContent = Get-Content $BaselinePath -Raw -ErrorAction Stop
                if ([string]::IsNullOrWhiteSpace($baselineContent)) {
                    throw "Baseline file is empty"
                }
                $baseline = $baselineContent | ConvertFrom-Json -ErrorAction Stop
            }
            catch {
                throw "Failed to parse baseline JSON: $($_.Exception.Message)"
            }
        }
        if ($null -eq $baseline) {
            throw "Failed to load baseline file"
        }
    }
    catch {
        Write-ScriptMessage -Message "Failed to load baseline file: $($_.Exception.Message)" -LogLevel 'Error'
        return @{
            Success       = $false
            Message       = "Failed to load baseline file"
            Regressions   = @()
            Improvements  = @()
            OverallChange = $null
        }
    }

    $comparison = @{
        Success       = $true
        BaselineDate  = $baseline.GeneratedAt
        CurrentDate   = Get-Date
        Regressions   = @()
        Improvements  = @()
        OverallChange = @{
            DurationChange  = $null
            TestCountChange = $TestResult.TotalCount - $baseline.TestSummary.TotalTests
        }
    }

    # Compare overall duration
    if ($baseline.TestSummary.Duration -and $TestResult.Time) {
        $baselineDuration = [TimeSpan]::Parse($baseline.TestSummary.Duration)
        $currentDuration = $TestResult.Time
        $durationChangePercent = (($currentDuration.TotalSeconds - $baselineDuration.TotalSeconds) / $baselineDuration.TotalSeconds) * 100

        $comparison.OverallChange.DurationChange = @{
            Baseline      = $baselineDuration
            Current       = $currentDuration
            ChangePercent = [Math]::Round($durationChangePercent, 2)
            IsRegression  = $durationChangePercent > $Threshold
            IsImprovement = $durationChangePercent -lt - $Threshold
        }
    }

    # Compare individual test performance
    if ($baseline.TestMetrics -and $TestResult.PassedTests) {
        foreach ($test in $TestResult.PassedTests) {
            if ($test.Duration -and $baseline.TestMetrics.PSObject.Properties.Name -contains $test.Name) {
                $baselineTest = $baseline.TestMetrics.$($test.Name)
                if ($baselineTest.Duration) {
                    $baselineTestDuration = [TimeSpan]::Parse($baselineTest.Duration)
                    $changePercent = (($test.Duration.TotalSeconds - $baselineTestDuration.TotalSeconds) / $baselineTestDuration.TotalSeconds) * 100

                    $testComparison = @{
                        TestName      = $test.Name
                        File          = $test.File
                        Baseline      = $baselineTestDuration
                        Current       = $test.Duration
                        ChangePercent = [Math]::Round($changePercent, 2)
                    }

                    if ($changePercent -gt $Threshold) {
                        $comparison.Regressions += $testComparison
                    }
                    elseif ($changePercent -lt - $Threshold) {
                        $comparison.Improvements += $testComparison
                    }
                }
            }
        }
    }

    return $comparison
}

<#
.SYNOPSIS
    Generates a performance regression report.

.DESCRIPTION
    Creates a detailed report of performance changes compared to baseline,
    highlighting regressions and improvements.

.PARAMETER Comparison
    The baseline comparison results.

.PARAMETER OutputPath
    Optional path to save the regression report.

.PARAMETER Threshold
    Threshold used for comparison.

.OUTPUTS
    Regression report content
#>
function New-PerformanceRegressionReport {
    param(
        [Parameter(Mandatory)]
        $Comparison,

        [string]$OutputPath,

        [ValidateRange(0, 100)]
        [int]$Threshold = 5
    )

    if (-not $Comparison.Success) {
        return "Performance regression analysis failed: $($Comparison.Message)"
    }

    $report = @"
Performance Regression Report
============================

Baseline Date: $($Comparison.BaselineDate)
Current Date:  $($Comparison.CurrentDate)

Overall Performance Changes:
----------------------------

"@

    if ($Comparison.OverallChange.DurationChange) {
        $change = $Comparison.OverallChange.DurationChange
        $baselineSeconds = [Math]::Round($change.Baseline.TotalSeconds, 2)
        $currentSeconds = [Math]::Round($change.Current.TotalSeconds, 2)
        $report += "Total Duration: ${baselineSeconds}s -> ${currentSeconds}s ($($change.ChangePercent)% change)`n"
        if ($change.IsRegression) {
            $report += "WARNING: Duration increased by more than $($Threshold)%`n"
        }
        elseif ($change.IsImprovement) {
            $report += "IMPROVEMENT: Duration decreased by more than $($Threshold)%`n"
        }
    }

    if ($Comparison.OverallChange.TestCountChange -ne 0) {
        $report += "Test Count Change: $($Comparison.OverallChange.TestCountChange) tests`n"
    }

    if ($Comparison.Regressions.Count -gt 0) {
        $report += "`n`nPerformance Regressions:`n------------------------`n"
        foreach ($regression in $Comparison.Regressions) {
            $baselineSeconds = [Math]::Round($regression.Baseline.TotalSeconds, 2)
            $currentSeconds = [Math]::Round($regression.Current.TotalSeconds, 2)
            $report += "WARNING: $($regression.TestName)`n    File: $($regression.File)`n    Duration: ${baselineSeconds}s -> ${currentSeconds}s ($($regression.ChangePercent)% change)`n"
        }
    }

    if ($Comparison.Improvements.Count -gt 0) {
        $report += "`n`nPerformance Improvements:`n-------------------------`n"
        foreach ($improvement in $Comparison.Improvements) {
            $baselineSeconds = [Math]::Round($improvement.Baseline.TotalSeconds, 2)
            $currentSeconds = [Math]::Round($improvement.Current.TotalSeconds, 2)
            $report += "IMPROVEMENT: $($improvement.TestName)`n    File: $($improvement.File)`n    Duration: ${baselineSeconds}s -> ${currentSeconds}s ($($improvement.ChangePercent)% change)`n"
        }
    }

    if ($Comparison.Regressions.Count -eq 0 -and $Comparison.Improvements.Count -eq 0) {
        $report += "`nNo significant performance changes detected.`n"
    }

    if ($OutputPath) {
        try {
            # Ensure output directory exists
            $outputDir = Split-Path -Path $OutputPath -Parent
            if ($outputDir -and -not (Test-Path -Path $outputDir)) {
                try {
                    New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
                }
                catch {
                    throw "Failed to create output directory '$outputDir': $($_.Exception.Message)"
                }
            }
            
            $report | Out-File -FilePath $OutputPath -Encoding UTF8 -ErrorAction Stop
            Write-ScriptMessage -Message "Performance regression report saved to: $OutputPath"
        }
        catch {
            Write-ScriptMessage -Message "Failed to save performance regression report to '$OutputPath': $($_.Exception.Message)" -LogLevel 'Error'
            throw
        }
    }

    return $report
}

Export-ModuleMember -Function @(
    'Compare-PerformanceBaseline',
    'New-PerformanceRegressionReport'
)

