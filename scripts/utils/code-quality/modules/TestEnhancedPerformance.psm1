<#
scripts/utils/code-quality/modules/TestEnhancedPerformance.psm1

.SYNOPSIS
    Enhanced performance monitoring utilities.

.DESCRIPTION
    Provides enhanced performance monitoring with detailed metrics, memory leak detection,
    and performance trend analysis.
#>

# Import TestPerformanceMonitoring module for Measure-TestPerformance
$performanceModulePath = Join-Path $PSScriptRoot 'TestPerformanceMonitoring.psm1'
if ($performanceModulePath -and -not [string]::IsNullOrWhiteSpace($performanceModulePath) -and (Test-Path -LiteralPath $performanceModulePath)) {
    Import-Module $performanceModulePath -DisableNameChecking -ErrorAction SilentlyContinue
}

<#
.SYNOPSIS
    Provides enhanced performance monitoring with detailed metrics.

.DESCRIPTION
    Extends basic performance monitoring with detailed resource tracking,
    memory leak detection, and performance trend analysis.

.PARAMETER ScriptBlock
    The script block to monitor.

.PARAMETER DetailedMetrics
    Enable collection of detailed performance metrics.

.PARAMETER DetectMemoryLeaks
    Enable memory leak detection.

.PARAMETER BaselineComparison
    Compare against performance baseline.

.OUTPUTS
    Enhanced performance metrics
#>
function Measure-EnhancedPerformance {
    param(
        [Parameter(Mandatory)]
        [scriptblock]$ScriptBlock,

        [switch]$DetailedMetrics,

        [switch]$DetectMemoryLeaks,

        $BaselineData
    )

    $metrics = @{
        StartTime              = Get-Date
        EndTime                = $null
        Duration               = $null
        MemoryMetrics          = @{}
        CPUMetrics             = @{}
        ThreadMetrics          = @{}
        MemoryLeakSuspects     = @()
        PerformanceDegradation = $null
    }

    # Get initial memory snapshot
    $initialMemory = Get-Process -Id $PID | Select-Object -ExpandProperty WorkingSet64

    try {
        # Execute with basic performance monitoring
        $basicResult = Measure-TestPerformance -ScriptBlock $ScriptBlock -TrackMemory -TrackCPU

        $metrics.EndTime = Get-Date
        $metrics.Duration = $metrics.EndTime - $metrics.StartTime

        # Enhanced memory analysis
        if ($DetailedMetrics) {
            $finalMemory = Get-Process -Id $PID | Select-Object -ExpandProperty WorkingSet64
            $memoryDelta = $finalMemory - $initialMemory

            $metrics.MemoryMetrics = @{
                InitialMB = [Math]::Round($initialMemory / 1MB, 2)
                FinalMB   = [Math]::Round($finalMemory / 1MB, 2)
                DeltaMB   = [Math]::Round($memoryDelta / 1MB, 2)
                PeakMB    = $basicResult.Performance.PeakMemoryMB
                AverageMB = $basicResult.Performance.AverageMemoryMB
            }

            # Memory leak detection
            if ($DetectMemoryLeaks -and $memoryDelta -gt 50MB) {
                $metrics.MemoryLeakSuspects += @{
                    ProcessId     = $PID
                    MemoryDeltaMB = [Math]::Round($memoryDelta / 1MB, 2)
                    Timestamp     = Get-Date
                }
            }
        }

        # CPU analysis
        if ($DetailedMetrics) {
            $metrics.CPUMetrics = @{
                AverageUsage = $basicResult.Performance.CPUUsage
                PeakUsage    = $null  # Would need more detailed tracking
            }
        }

        # Thread analysis
        $threadCount = Get-Process -Id $PID | Select-Object -ExpandProperty Threads | Measure-Object | Select-Object -ExpandProperty Count
        $metrics.ThreadMetrics = @{
            InitialCount = $null  # Would need baseline
            FinalCount   = $threadCount
            DeltaCount   = $null  # Would need baseline
        }

        # Baseline comparison
        if ($BaselineData) {
            $baselineDuration = [TimeSpan]::Parse($BaselineData.TestSummary.Duration)
            $currentDuration = $metrics.Duration

            $durationChangePercent = (($currentDuration.TotalSeconds - $baselineDuration.TotalSeconds) / $baselineDuration.TotalSeconds) * 100

            $metrics.PerformanceDegradation = @{
                BaselineDuration = $baselineDuration
                CurrentDuration  = $currentDuration
                ChangePercent    = [Math]::Round($durationChangePercent, 2)
                IsDegraded       = $durationChangePercent > 10  # 10% degradation threshold
                IsImproved       = $durationChangePercent -lt -5 # 5% improvement threshold
            }
        }

        return @{
            Result   = $basicResult.Result
            Metrics  = $metrics
            Enhanced = $true
        }
    }
    catch {
        $metrics.Error = $_.Exception.Message
        return @{
            Result   = $null
            Metrics  = $metrics
            Enhanced = $false
            Error    = $_
        }
    }
}

Export-ModuleMember -Function Measure-EnhancedPerformance

