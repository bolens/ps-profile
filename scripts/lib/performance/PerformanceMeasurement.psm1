<#
scripts/lib/PerformanceMeasurement.psm1

.SYNOPSIS
    Performance measurement utilities.

.DESCRIPTION
    Provides functions for measuring operation execution time and logging metrics.
    Can optionally record metrics to SQLite database for persistent storage.
#>

# Import SafeImport module if available for safer imports
# Note: We need to use manual check here since SafeImport itself uses Validation
$safeImportModulePath = Join-Path (Split-Path -Parent $PSScriptRoot) 'core' 'SafeImport.psm1'
if ($safeImportModulePath -and -not [string]::IsNullOrWhiteSpace($safeImportModulePath) -and (Test-Path -LiteralPath $safeImportModulePath)) {
    Import-Module $safeImportModulePath -DisableNameChecking -ErrorAction SilentlyContinue
}

# Import Logging module for Write-ScriptMessage
$loggingModulePath = Join-Path $PSScriptRoot 'Logging.psm1'
if (Get-Command Import-ModuleSafely -ErrorAction SilentlyContinue) {
    Import-ModuleSafely -ModulePath $loggingModulePath -ErrorAction SilentlyContinue
}
else {
    # Fallback to manual validation
    if ($loggingModulePath -and -not [string]::IsNullOrWhiteSpace($loggingModulePath) -and (Test-Path -LiteralPath $loggingModulePath)) {
        Import-Module $loggingModulePath -ErrorAction SilentlyContinue
    }
}

# Try to import Performance Metrics Database module for persistent storage
$performanceMetricsModule = Join-Path (Split-Path -Parent $PSScriptRoot) 'database' 'PerformanceMetricsDatabase.psm1'
$script:UsePerformanceMetricsDb = $false
if ($performanceMetricsModule -and (Test-Path -LiteralPath $performanceMetricsModule)) {
    try {
        Import-Module $performanceMetricsModule -DisableNameChecking -ErrorAction SilentlyContinue
        if (Get-Command Add-PerformanceMetric -ErrorAction SilentlyContinue) {
            $script:UsePerformanceMetricsDb = $true
        }
    }
    catch {
        # Performance metrics database not available, continue without it
    }
}

<#
.SYNOPSIS
    Measures execution time of a scriptblock and optionally logs metrics.

.DESCRIPTION
    Wraps a scriptblock execution with timing measurement. Can output structured
    metrics for performance monitoring and telemetry.

.PARAMETER ScriptBlock
    The scriptblock to measure.

.PARAMETER OperationName
    Optional name for the operation being measured.

.PARAMETER LogMetrics
    If specified, logs the metrics using Write-ScriptMessage with structured output.

.OUTPUTS
    PSCustomObject with OperationName, DurationMs, StartTime, EndTime, and Success properties.

.EXAMPLE
    $metrics = Measure-Operation -ScriptBlock { Get-Process } -OperationName "GetProcess"
    Write-Output "Operation took $($metrics.DurationMs)ms"

.EXAMPLE
    Measure-Operation -ScriptBlock { Invoke-ScriptAnalyzer -Path $file } -OperationName "ScriptAnalysis" -LogMetrics
#>
function Measure-Operation {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory)]
        [scriptblock]$ScriptBlock,

        [string]$OperationName = "Operation",

        [switch]$LogMetrics
    )

    $startTime = [DateTime]::UtcNow
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    $success = $false
    $errorMessage = $null
    
    $debugLevel = 0
    if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel) -and $debugLevel -ge 3) {
        Write-Verbose "[performance-measurement.measure] Starting measurement for operation: $OperationName"
    }

    try {
        $result = & $ScriptBlock
        $success = $true
    }
    catch {
        $errorMessage = $_.Exception.Message
        $debugLevel = 0
        if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel)) {
            if ($debugLevel -ge 1) {
                if (Get-Command Write-StructuredWarning -ErrorAction SilentlyContinue) {
                    Write-StructuredWarning -Message "Operation failed during measurement" -OperationName 'performance-measurement.measure' -Context @{
                        # Technical context
                        OperationName = $OperationName
                        # Error context
                        ErrorMessage  = $errorMessage
                        ErrorType     = $_.Exception.GetType().FullName
                        # Invocation context
                        FunctionName  = 'Measure-Operation'
                    } -Code 'OperationFailed'
                }
                else {
                    Write-Warning "[performance-measurement.measure] Operation '$OperationName' failed: $errorMessage"
                }
            }
            # Level 3: Log detailed error information
            if ($debugLevel -ge 3) {
                Write-Verbose "[performance-measurement.measure] Operation failure details - OperationName: $OperationName, Exception: $($_.Exception.GetType().FullName), Message: $errorMessage, Stack: $($_.ScriptStackTrace)"
            }
        }
        else {
            # Always log warnings even if debug is off
            if (Get-Command Write-StructuredWarning -ErrorAction SilentlyContinue) {
                Write-StructuredWarning -Message "Operation failed during measurement" -OperationName 'performance-measurement.measure' -Context @{
                    OperationName = $OperationName
                    ErrorMessage  = $errorMessage
                    ErrorType     = $_.Exception.GetType().FullName
                    FunctionName  = 'Measure-Operation'
                } -Code 'OperationFailed'
            }
            else {
                Write-Warning "[performance-measurement.measure] Operation '$OperationName' failed: $errorMessage"
            }
        }
        # Don't re-throw - return metrics with error information instead
        # This allows callers to check Success property and ErrorMessage
    }
    finally {
        $stopwatch.Stop()
        $endTime = [DateTime]::UtcNow
        $durationMs = $stopwatch.Elapsed.TotalMilliseconds

        $metrics = [PSCustomObject]@{
            OperationName = $OperationName
            DurationMs    = [math]::Round($durationMs, 2)
            StartTime     = $startTime.ToString('o')
            EndTime       = $endTime.ToString('o')
            Success       = $success
            ErrorMessage  = $errorMessage
        }
        
        $debugLevel = 0
        if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel) -and $debugLevel -ge 2) {
            Write-Verbose "[performance-measurement.measure] Operation '$OperationName' completed: Duration=$([math]::Round($durationMs, 2))ms, Success=$success"
        }
        
        if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel) -and $debugLevel -ge 3) {
            Write-Verbose "[performance-measurement.measure] Detailed metrics: StartTime=$($startTime.ToString('o')), EndTime=$($endTime.ToString('o'))"
        }

        if ($LogMetrics) {
            if (Get-Command Write-ScriptMessage -ErrorAction SilentlyContinue) {
                $metricsJson = $metrics | ConvertTo-Json -Compress
                Write-ScriptMessage -Message "PerformanceMetrics: $metricsJson" -LogLevel Info -StructuredOutput
            }
        }
        
        # Record to persistent database if available
        if ($script:UsePerformanceMetricsDb) {
            try {
                # Determine environment
                $environment = if ($env:CI) { 'CI' } elseif ($env:PS_PROFILE_ENVIRONMENT) { $env:PS_PROFILE_ENVIRONMENT } else { 'local' }
                
                # Record the metric
                Add-PerformanceMetric -MetricType 'operation' -MetricName $OperationName -Value $durationMs -Unit 'ms' -Environment $environment -Metadata @{
                    Success      = $success
                    ErrorMessage = $errorMessage
                }
            }
            catch {
                # Level 1: Log error
                $debugLevel = 0
                if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel)) {
                    if ($debugLevel -ge 1) {
                        if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                            Write-StructuredError -ErrorRecord $_ -OperationName 'performance-measurement.record' -Context @{
                                operation_name = $OperationName
                                metric_type    = 'operation'
                            }
                        }
                        else {
                            Write-Warning "Failed to record metric to database: $($_.Exception.Message)"
                        }
                    }
                    if ($debugLevel -ge 2) {
                        Write-Verbose "[performance-measurement.record] Database recording error: $($_.Exception.Message)"
                    }
                    if ($debugLevel -ge 3) {
                        Write-Host "  [performance-measurement.record] Database error details - Exception: $($_.Exception.GetType().FullName), Message: $($_.Exception.Message), OperationName: $OperationName" -ForegroundColor DarkGray
                    }
                }
            }
        }
    }

    return $metrics
}

Export-ModuleMember -Function Measure-Operation

