<#
scripts/utils/code-quality/modules/TestPerformanceMonitoring.psm1

.SYNOPSIS
    Test performance monitoring utilities.

.DESCRIPTION
    Provides functions for monitoring test execution performance and resource usage.
#>

# Import Logging module for Write-ScriptMessage
$loggingModulePath = Join-Path (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)))) 'lib' 'Logging.psm1'
if (Test-Path $loggingModulePath) {
    Import-Module $loggingModulePath -DisableNameChecking -ErrorAction SilentlyContinue
}

<#
.SYNOPSIS
    Monitors test execution performance and resource usage.

.DESCRIPTION
    Tracks execution time, memory usage, and other performance metrics
    during test execution.

.PARAMETER ScriptBlock
    The script block to monitor.

.PARAMETER TrackMemory
    Enable memory usage tracking (default: false).

.PARAMETER TrackCPU
    Enable CPU usage tracking (default: false).

.OUTPUTS
    Performance metrics object
#>
function Measure-TestPerformance {
    param(
        [Parameter(Mandatory)]
        [scriptblock]$ScriptBlock,

        [switch]$TrackMemory,

        [switch]$TrackCPU
    )

    $metrics = @{
        StartTime       = Get-Date
        EndTime         = $null
        Duration        = $null
        MemoryUsage     = $null
        CPUUsage        = $null
        PeakMemoryMB    = 0
        AverageMemoryMB = 0
    }

    $memorySamples = @()
    $cpuSamples = @()

    # Start performance monitoring job if tracking is enabled
    $monitorJob = $null
    if ($TrackMemory -or $TrackCPU) {
        $monitorJob = Start-Job -Name 'PerformanceMonitor' -ScriptBlock {
            param($TrackMemory, $TrackCPU, $ParentProcessId)

            $samples = @{
                Memory = @()
                CPU    = @()
            }

            $startTime = Get-Date
            $lastParentCheck = Get-Date
            while ($true) {
                try {
                    # Check if parent process is still running (with timeout)
                    if (((Get-Date) - $lastParentCheck).TotalSeconds -gt 5) {
                        $parentProcess = Get-Process -Id $ParentProcessId -ErrorAction Stop
                        $lastParentCheck = Get-Date
                    }
                }
                catch {
                    # Parent process ended
                    break
                }

                if ($TrackMemory) {
                    try {
                        $process = Get-Process -Id $ParentProcessId -ErrorAction Stop
                        $memoryMB = [Math]::Round($process.WorkingSet64 / 1MB, 2)
                        $samples.Memory += $memoryMB
                    }
                    catch {
                        # Process might have ended
                        break
                    }
                }

                if ($TrackCPU) {
                    try {
                        # Use a timeout for CPU monitoring to prevent hanging
                        $cpuJob = $null
                        try {
                            $cpuJob = Start-Job -ScriptBlock {
                                param($ProcessId)
                                try {
                                    $cpu = Get-Counter '\Process(*)\% Processor Time' -MaxSamples 1 -ErrorAction Stop |
                                    Where-Object { $_.CounterSamples.InstanceName -eq (Get-Process -Id $ProcessId).Name } |
                                    Select-Object -ExpandProperty CounterSamples |
                                    Select-Object -ExpandProperty CookedValue
                                    return $cpu
                                }
                                catch {
                                    return $null
                                }
                            } -ArgumentList $ParentProcessId -ThrottleLimit 1 -ErrorAction Stop
                        }
                        catch {
                            Write-Verbose "Failed to start CPU monitoring job: $($_.Exception.Message)"
                            # Continue without CPU monitoring
                            $cpuJob = $null
                        }

                        if ($null -ne $cpuJob) {
                            # Wait for CPU job with timeout
                            try {
                                $cpuResult = $cpuJob | Wait-Job -Timeout 2 | Receive-Job
                                if ($cpuResult -and $cpuResult -is [double]) {
                                    $samples.CPU += [Math]::Round($cpuResult, 2)
                                }
                            }
                            catch {
                                Write-Verbose "CPU monitoring job failed or timed out: $($_.Exception.Message)"
                            }
                            finally {
                                if ($cpuJob) {
                                    Remove-Job -Job $cpuJob -Force -ErrorAction SilentlyContinue
                                }
                            }
                        }
                    }
                    catch {
                        # CPU monitoring failed or timed out, continue
                        Write-Verbose "CPU monitoring error: $($_.Exception.Message)"
                    }
                }

                Start-Sleep -Milliseconds 500  # Reduce frequency to prevent excessive CPU usage

                # Timeout after 30 minutes to prevent runaway jobs (reduced from 1 hour)
                if (((Get-Date) - $startTime).TotalMinutes -gt 30) {
                    break
                }
            }

            return $samples
        } -ArgumentList $TrackMemory, $TrackCPU, $PID
    }

    try {
        # Execute the test script block
        $result = & $ScriptBlock
    }
    finally {
        $metrics.EndTime = Get-Date
        $metrics.Duration = $metrics.EndTime - $metrics.StartTime

        # Collect performance data
        if ($monitorJob) {
            Stop-Job -Job $monitorJob -ErrorAction SilentlyContinue
            $performanceData = Receive-Job -Job $monitorJob -Wait -AutoRemoveJob

            if ($TrackMemory -and $performanceData.Memory) {
                $metrics.PeakMemoryMB = ($performanceData.Memory | Measure-Object -Maximum).Maximum
                $metrics.AverageMemoryMB = ($performanceData.Memory | Measure-Object -Average).Average
            }

            if ($TrackCPU -and $performanceData.CPU) {
                $metrics.CPUUsage = ($performanceData.CPU | Measure-Object -Average).Average
            }
        }
    }

    return @{
        Result      = $result
        Performance = $metrics
    }
}

<#
.SYNOPSIS
    Wraps test execution with performance tracking.

.DESCRIPTION
    Executes a test execution script block with optional performance monitoring,
    handling errors gracefully and falling back to regular execution if needed.

.PARAMETER ExecutionScriptBlock
    The script block to execute with performance tracking.

.PARAMETER Config
    The Pester configuration object.

.PARAMETER RunNumber
    Current run number.

.PARAMETER TotalRuns
    Total number of runs.

.PARAMETER TrackMemory
    Enable memory tracking.

.PARAMETER TrackCPU
    Enable CPU tracking.

.OUTPUTS
    Test result with optional performance data
#>
function Invoke-TestExecutionWithPerformance {
    param(
        [Parameter(Mandatory)]
        [scriptblock]$ExecutionScriptBlock,

        [Parameter(Mandatory)]
        $Config,

        [int]$RunNumber = 1,

        [int]$TotalRuns = 1,

        [switch]$TrackMemory,

        [switch]$TrackCPU
    )

    try {
        $perfResult = Measure-TestPerformance -ScriptBlock {
            & $ExecutionScriptBlock $Config $RunNumber $TotalRuns
        } -TrackMemory:$TrackMemory -TrackCPU:$TrackCPU

        # Validate performance result structure
        if ($perfResult -and $perfResult.Result) {
            return $perfResult
        }
        else {
            Write-ScriptMessage -Message "Performance tracking returned invalid result, falling back to regular execution" -LogLevel 'Warning'
            return & $ExecutionScriptBlock $Config $RunNumber $TotalRuns
        }
    }
    catch {
        Write-ScriptMessage -Message "Performance tracking failed: $($_.Exception.Message)" -LogLevel 'Warning'
        # Fall back to regular execution
        try {
            return & $ExecutionScriptBlock $Config $RunNumber $TotalRuns
        }
        catch {
            Write-ScriptMessage -Message "Fallback execution also failed: $($_.Exception.Message)" -LogLevel 'Error'
            throw
        }
    }
}

Export-ModuleMember -Function @(
    'Measure-TestPerformance',
    'Invoke-TestExecutionWithPerformance'
)

