<#
scripts/utils/code-quality/modules/TestSummaryStats.psm1

.SYNOPSIS
    Enhanced test summary statistics utilities.

.DESCRIPTION
    Provides functions for generating detailed test summary statistics including
    slowest tests, retry counts, failure patterns, and more.
#>

# Import Logging module
$loggingModulePath = Join-Path (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)))) 'lib' 'core' 'Logging.psm1'
if ($loggingModulePath -and -not [string]::IsNullOrWhiteSpace($loggingModulePath) -and (Test-Path -LiteralPath $loggingModulePath)) {
    Import-Module $loggingModulePath -DisableNameChecking -ErrorAction SilentlyContinue
}

# Import Locale module for locale-aware number formatting
$localeModulePath = Join-Path (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)))) 'lib' 'core' 'Locale.psm1'
if ($localeModulePath -and -not [string]::IsNullOrWhiteSpace($localeModulePath) -and (Test-Path -LiteralPath $localeModulePath)) {
    Import-Module $localeModulePath -DisableNameChecking -ErrorAction SilentlyContinue
}

<#
.SYNOPSIS
    Generates enhanced summary statistics from test results.

.DESCRIPTION
    Analyzes test results and generates detailed statistics including slowest tests,
    most retried tests, failure patterns, and performance insights.

.PARAMETER TestResult
    Pester test result object.

.PARAMETER PerformanceData
    Optional performance tracking data.

.PARAMETER ShowSlowest
    Number of slowest tests to show. Defaults to 5.

.PARAMETER ShowDetails
    Show detailed statistics.

.OUTPUTS
    Hashtable with summary statistics
#>
function Get-TestSummaryStatistics {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory)]
        [object]$TestResult,
        [hashtable]$PerformanceData,
        [int]$ShowSlowest = 5,
        [switch]$ShowDetails
    )

    $stats = @{
        TotalTests      = $TestResult.TotalCount
        PassedTests     = $TestResult.PassedCount
        FailedTests     = $TestResult.FailedCount
        SkippedTests    = $TestResult.SkippedCount
        NotRunTests     = $TestResult.NotRunCount
        Duration        = $TestResult.Duration
        SlowestTests    = @()
        FailedTestNames = @()
        FailurePatterns = @()
    }

    # Extract test details if available
    if ($TestResult.Tests) {
        # Get slowest tests
        $testDurations = $TestResult.Tests | 
        Where-Object { $_.Duration } | 
        Sort-Object Duration -Descending | 
        Select-Object -First $ShowSlowest
        
        $stats.SlowestTests = $testDurations | ForEach-Object {
            @{
                Name     = $_.Name
                Duration = $_.Duration
                Result   = $_.Result
            }
        }

        # Get failed test names
        $stats.FailedTestNames = $TestResult.Tests | 
        Where-Object { $_.Result -eq 'Failed' } | 
        Select-Object -ExpandProperty Name

        # Analyze failure patterns
        $failureMessages = $TestResult.Tests | 
        Where-Object { $_.Result -eq 'Failed' -and $_.ErrorRecord } | 
        ForEach-Object { $_.ErrorRecord.Exception.Message }

        if ($failureMessages) {
            # Group by common patterns
            $patternGroups = $failureMessages | Group-Object | Sort-Object Count -Descending
            $stats.FailurePatterns = $patternGroups | Select-Object -First 5 | ForEach-Object {
                @{
                    Pattern = $_.Name
                    Count   = $_.Count
                }
            }
        }
    }

    # Add performance insights if available
    if ($PerformanceData) {
        $stats.PerformanceData = @{
            PeakMemory    = $PerformanceData.PeakMemory
            AverageMemory = $PerformanceData.AverageMemory
            PeakCPU       = $PerformanceData.PeakCPU
            AverageCPU    = $PerformanceData.AverageCPU
        }
    }

    return $stats
}

<#
.SYNOPSIS
    Displays enhanced test summary statistics.

.DESCRIPTION
    Outputs formatted summary statistics to the console.

.PARAMETER Statistics
    Hashtable returned from Get-TestSummaryStatistics.

.PARAMETER ShowSlowest
    Show slowest tests section.

.PARAMETER ShowFailurePatterns
    Show failure patterns section.
#>
function Show-TestSummaryStatistics {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$Statistics,
        [switch]$ShowSlowest,
        [switch]$ShowFailurePatterns
    )

    Write-Host "`n=== Test Summary Statistics ===" -ForegroundColor Cyan
    Write-Host "Total Tests:    $($Statistics.TotalTests)" -ForegroundColor White
    Write-Host "Passed:         $($Statistics.PassedTests)" -ForegroundColor Green
    Write-Host "Failed:         $($Statistics.FailedTests)" -ForegroundColor $(if ($Statistics.FailedTests -gt 0) { 'Red' } else { 'Green' })
    Write-Host "Skipped:        $($Statistics.SkippedTests)" -ForegroundColor Yellow
    Write-Host "Not Run:        $($Statistics.NotRunTests)" -ForegroundColor Gray
    
    if ($Statistics.Duration) {
        $durationSeconds = if (Get-Command Format-LocaleNumber -ErrorAction SilentlyContinue) {
            Format-LocaleNumber ([Math]::Round($Statistics.Duration.TotalSeconds, 2)) -Format 'N2'
        }
        else {
            [Math]::Round($Statistics.Duration.TotalSeconds, 2).ToString("N2")
        }
        Write-Host "Duration:       ${durationSeconds}s" -ForegroundColor White
    }

    # Show slowest tests
    if ($ShowSlowest -and $Statistics.SlowestTests.Count -gt 0) {
        Write-Host "`n=== Slowest Tests ===" -ForegroundColor Yellow
        foreach ($test in $Statistics.SlowestTests) {
            $durationSeconds = if (Get-Command Format-LocaleNumber -ErrorAction SilentlyContinue) {
                Format-LocaleNumber ([Math]::Round($test.Duration.TotalSeconds, 2)) -Format 'N2'
            }
            else {
                [Math]::Round($test.Duration.TotalSeconds, 2).ToString("N2")
            }
            $color = if ($test.Result -eq 'Failed') { 'Red' } else { 'White' }
            Write-Host "  $($test.Name): ${durationSeconds}s" -ForegroundColor $color
        }
    }

    # Show failure patterns
    if ($ShowFailurePatterns -and $Statistics.FailurePatterns.Count -gt 0) {
        Write-Host "`n=== Common Failure Patterns ===" -ForegroundColor Red
        foreach ($pattern in $Statistics.FailurePatterns) {
            Write-Host "  [$($pattern.Count)x] $($pattern.Pattern)" -ForegroundColor Gray
        }
    }

    # Show performance data if available
    if ($Statistics.PerformanceData) {
        Write-Host "`n=== Performance Metrics ===" -ForegroundColor Cyan
        if ($Statistics.PerformanceData.PeakMemory) {
            $peakMB = if (Get-Command Format-LocaleNumber -ErrorAction SilentlyContinue) {
                Format-LocaleNumber ([Math]::Round($Statistics.PerformanceData.PeakMemory / 1MB, 2)) -Format 'N2'
            }
            else {
                [Math]::Round($Statistics.PerformanceData.PeakMemory / 1MB, 2).ToString("N2")
            }
            Write-Host "Peak Memory:    ${peakMB} MB" -ForegroundColor White
        }
        if ($Statistics.PerformanceData.AverageCPU) {
            $avgCPU = if (Get-Command Format-LocaleNumber -ErrorAction SilentlyContinue) {
                Format-LocaleNumber ([Math]::Round($Statistics.PerformanceData.AverageCPU, 1)) -Format 'N1'
            }
            else {
                [Math]::Round($Statistics.PerformanceData.AverageCPU, 1).ToString("N1")
            }
            Write-Host "Average CPU:    ${avgCPU}%" -ForegroundColor White
        }
    }

    Write-Host ""
}

Export-ModuleMember -Function @(
    'Get-TestSummaryStatistics',
    'Show-TestSummaryStatistics'
)

