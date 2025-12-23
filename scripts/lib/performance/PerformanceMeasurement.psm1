<#
scripts/lib/PerformanceMeasurement.psm1

.SYNOPSIS
    Performance measurement utilities.

.DESCRIPTION
    Provides functions for measuring operation execution time and logging metrics.
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

    try {
        $result = & $ScriptBlock
        $success = $true
    }
    catch {
        $errorMessage = $_.Exception.Message
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

        if ($LogMetrics) {
            if (Get-Command Write-ScriptMessage -ErrorAction SilentlyContinue) {
                $metricsJson = $metrics | ConvertTo-Json -Compress
                Write-ScriptMessage -Message "PerformanceMetrics: $metricsJson" -LogLevel Info -StructuredOutput
            }
        }
    }

    return $metrics
}

Export-ModuleMember -Function Measure-Operation

