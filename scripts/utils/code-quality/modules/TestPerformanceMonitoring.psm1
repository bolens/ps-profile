<#
scripts/utils/code-quality/modules/TestPerformanceMonitoring.psm1

.SYNOPSIS
    Test performance monitoring utilities.

.DESCRIPTION
    Provides functions for monitoring test execution performance and resource usage.
#>

# Import Logging module for Write-ScriptMessage
$loggingModulePath = Join-Path (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)))) 'lib' 'core' 'Logging.psm1'
if ($loggingModulePath -and -not [string]::IsNullOrWhiteSpace($loggingModulePath) -and (Test-Path -LiteralPath $loggingModulePath)) {
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

    # Start performance monitoring runspace if tracking is enabled
    $monitorRunspace = $null
    $monitorPool = $null
    $monitorHandle = $null
    
    if ($TrackMemory -or $TrackCPU) {
        try {
            $monitorPool = [runspacefactory]::CreateRunspacePool(1, 1)
            $monitorPool.Open()
            
            $monitorRunspace = [PowerShell]::Create()
            $monitorRunspace.RunspacePool = $monitorPool
            
            $scriptBlock = {
                param($TrackMemory, $TrackCPU, $ParentProcessId)

                $samples = New-Object System.Collections.ArrayList

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

                    $sample = @{
                        Memory = $null
                        CPU    = $null
                        Time   = Get-Date
                    }

                    if ($TrackMemory) {
                        try {
                            $process = Get-Process -Id $ParentProcessId -ErrorAction Stop
                            $sample.Memory = [Math]::Round($process.WorkingSet64 / 1MB, 2)
                        }
                        catch {
                            # Process might have ended
                            break
                        }
                    }

                    if ($TrackCPU) {
                        try {
                            # Use Get-Counter directly (no need for nested job in runspace)
                            $cpu = Get-Counter '\Process(*)\% Processor Time' -MaxSamples 1 -ErrorAction SilentlyContinue |
                            Where-Object { $_.CounterSamples.InstanceName -eq (Get-Process -Id $ParentProcessId -ErrorAction SilentlyContinue).Name } |
                            Select-Object -ExpandProperty CounterSamples |
                            Select-Object -ExpandProperty CookedValue
                            if ($cpu -and $cpu -is [double]) {
                                $sample.CPU = [Math]::Round($cpu, 2)
                            }
                        }
                        catch {
                            Write-Verbose "CPU monitoring error: $($_.Exception.Message)"
                        }
                    }

                    [void]$samples.Add($sample)
                    Start-Sleep -Milliseconds 500  # Reduce frequency to prevent excessive CPU usage

                    # Timeout after 30 minutes to prevent runaway monitoring
                    if (((Get-Date) - $startTime).TotalMinutes -gt 30) {
                        break
                    }
                }

                # Convert to hashtable format for compatibility
                $result = @{
                    Memory = @()
                    CPU    = @()
                }
                foreach ($s in $samples) {
                    if ($null -ne $s.Memory) {
                        $result.Memory += $s.Memory
                    }
                    if ($null -ne $s.CPU) {
                        $result.CPU += $s.CPU
                    }
                }
                return $result
            }
            
            $null = $monitorRunspace.AddScript($scriptBlock)
            $null = $monitorRunspace.AddArgument($TrackMemory)
            $null = $monitorRunspace.AddArgument($TrackCPU)
            $null = $monitorRunspace.AddArgument($PID)
            $monitorHandle = $monitorRunspace.BeginInvoke()
        }
        catch {
            Write-Verbose "Failed to start performance monitoring: $($_.Exception.Message)"
        }
    }

    try {
        # Execute the test script block
        $result = & $ScriptBlock
    }
    finally {
        $metrics.EndTime = Get-Date
        $metrics.Duration = $metrics.EndTime - $metrics.StartTime

        # Collect performance data
        if ($monitorRunspace -and $monitorHandle) {
            try {
                # Stop monitoring
                $monitorRunspace.Stop()
                
                # Wait a moment for cleanup
                Start-Sleep -Milliseconds 100
                
                # Get results if completed
                if ($monitorHandle.IsCompleted) {
                    $performanceData = $monitorRunspace.EndInvoke($monitorHandle)
                }
                else {
                    # Timeout or stopped, create empty result
                    $performanceData = @{
                        Memory = @()
                        CPU    = @()
                    }
                }
            }
            catch {
                Write-Verbose "Error collecting performance data: $($_.Exception.Message)"
                $performanceData = @{
                    Memory = @()
                    CPU    = @()
                }
            }
            finally {
                if ($monitorRunspace) {
                    $monitorRunspace.Dispose()
                }
                if ($monitorPool) {
                    $monitorPool.Close()
                    $monitorPool.Dispose()
                }
            }

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

