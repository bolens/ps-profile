<#
scripts/lib/Performance.psm1

.SYNOPSIS
    Performance measurement and regression detection utilities.

.DESCRIPTION
    Provides functions for measuring operation performance, detecting regressions,
    and aggregating performance metrics.

.NOTES
    Module Version: 1.0.0
    PowerShell Version: 3.0+
#>

# Import Logging module for Write-ScriptMessage
$loggingModulePath = Join-Path $PSScriptRoot 'Logging.psm1'
if (Test-Path $loggingModulePath) {
    Import-Module $loggingModulePath -ErrorAction SilentlyContinue
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
        throw
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

<#
.SYNOPSIS
    Detects performance regressions by comparing current metrics against a baseline.

.DESCRIPTION
    Compares current performance metrics against a baseline file to detect regressions.
    Useful for CI/CD pipelines and automated performance testing.

.PARAMETER CurrentMetrics
    Hashtable or PSCustomObject with current performance metrics.
    Expected structure: Key-value pairs where keys are metric names (e.g., 'DurationMs', 'MemoryMB')
    and values are numeric (double, int, or long). Values should be greater than 0 for meaningful comparison.
    Type: [hashtable] or [PSCustomObject]. Accepts hashtable for direct use, or PSCustomObject for flexibility.

.PARAMETER BaselineFile
    Path to the baseline JSON file containing historical metrics.
    File should contain JSON with metric keys matching CurrentMetrics keys.

.PARAMETER Threshold
    Performance regression threshold (default: 1.5 = 50% degradation).
    A ratio above this threshold indicates a regression.

.PARAMETER OperationName
    Name of the operation being measured (for reporting).

.OUTPUTS
    PSCustomObject with RegressionDetected (bool), Ratio (double), and Details (array) properties.
    Expected properties: RegressionDetected ([bool]), Ratio ([double]), Details ([PSCustomObject[]]),
    OperationName ([string]), Message ([string]).

.EXAMPLE
    $metrics = @{ DurationMs = 1200 }
    $result = Test-PerformanceRegression -CurrentMetrics $metrics -BaselineFile "baseline.json"
    if ($result.RegressionDetected) {
        Write-Warning "Performance regression detected!"
    }
#>
function Test-PerformanceRegression {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory)]
        [object]$CurrentMetrics,

        [Parameter(Mandatory)]
        [string]$BaselineFile,

        [double]$Threshold = 1.5,

        [string]$OperationName = "Operation"
    )

    # Validate CurrentMetrics structure
    if ($null -eq $CurrentMetrics) {
        throw "CurrentMetrics cannot be null"
    }

    # Convert PSCustomObject to hashtable if needed
    $metricsHash = if ($CurrentMetrics -is [hashtable]) {
        $CurrentMetrics
    }
    elseif ($CurrentMetrics -is [PSCustomObject]) {
        $hash = @{}
        $CurrentMetrics.PSObject.Properties | ForEach-Object {
            $hash[$_.Name] = $_.Value
        }
        $hash
    }
    else {
        throw "CurrentMetrics must be a Hashtable or PSCustomObject. Received type: $($CurrentMetrics.GetType().Name)"
    }

    if ($metricsHash.Count -eq 0) {
        Write-Warning "CurrentMetrics is empty. No metrics to compare."
    }

    $regressionDetected = $false
    $regressions = [System.Collections.Generic.List[PSCustomObject]]::new()

    if (-not (Test-Path -Path $BaselineFile)) {
        Write-Verbose "Baseline file not found: $BaselineFile"
        return [PSCustomObject]@{
            RegressionDetected = $false
            Ratio              = 1.0
            Details            = @()
            Message            = "No baseline found"
        }
    }

    try {
        $baseline = Get-Content -Path $BaselineFile -Raw | ConvertFrom-Json

        # Compare metrics
        foreach ($key in $metricsHash.Keys) {
            if ($baseline.PSObject.Properties.Name -contains $key) {
                $currentValue = $metricsHash[$key]
                $baselineValue = $baseline.$key

                if ($null -ne $currentValue -and $null -ne $baselineValue -and $baselineValue -gt 0) {
                    $ratio = $currentValue / $baselineValue

                    if ($ratio -gt $Threshold) {
                        $regressionDetected = $true
                        $regressions.Add([PSCustomObject]@{
                                Metric      = $key
                                Current     = $currentValue
                                Baseline    = $baselineValue
                                Ratio       = [math]::Round($ratio, 2)
                                Degradation = [math]::Round(($ratio - 1) * 100, 1)
                            })
                    }
                }
            }
        }
    }
    catch {
        Write-Warning "Failed to load baseline: $($_.Exception.Message)"
        return [PSCustomObject]@{
            RegressionDetected = $false
            Ratio              = 1.0
            Details            = @()
            Message            = "Error loading baseline: $($_.Exception.Message)"
        }
    }

    return [PSCustomObject]@{
        RegressionDetected = $regressionDetected
        Ratio              = if ($regressions.Count -gt 0) { ($regressions | Measure-Object -Property Ratio -Maximum).Maximum } else { 1.0 }
        Details            = $regressions.ToArray()
        OperationName      = $OperationName
    }
}

<#
.SYNOPSIS
    Aggregates and reports performance metrics from multiple operations.

.DESCRIPTION
    Collects metrics from multiple Measure-Operation calls and provides
    aggregated statistics including totals, averages, min/max, and percentiles.

.PARAMETER Metrics
    Array of metrics objects from Measure-Operation calls.
    Expected object properties: DurationMs ([double]), Success ([bool]).
    Each object should be a PSCustomObject returned by Measure-Operation.
    Type: [object[]] or [PSCustomObject[]].

.PARAMETER OperationName
    Optional name for the aggregated operation set.

.OUTPUTS
    PSCustomObject with aggregated statistics.

.EXAMPLE
    $metrics1 = Measure-Operation -ScriptBlock { Get-Process } -OperationName "GetProcess1"
    $metrics2 = Measure-Operation -ScriptBlock { Get-Process } -OperationName "GetProcess2"
    $aggregated = Get-AggregatedMetrics -Metrics @($metrics1, $metrics2) -OperationName "GetProcess"
    Write-Output "Average duration: $($aggregated.AverageDurationMs)ms"
#>
function Get-AggregatedMetrics {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory)]
        [AllowEmptyCollection()]
        [object[]]$Metrics,

        [string]$OperationName = "Operations"
    )

    # Validate Metrics array contains objects with expected properties
    $validatedMetrics = [System.Collections.Generic.List[object]]::new()

    foreach ($metric in $Metrics) {
        if ($null -eq $metric) {
            Write-Warning "Metrics array contains null value. Skipping."
            continue
        }

        $hasDuration = $false

        if ($metric -is [System.Collections.IDictionary]) {
            $hasDuration = $metric.Contains('DurationMs')
        }
        else {
            $prop = $metric.PSObject.Properties['DurationMs']
            if ($null -ne $prop) {
                $hasDuration = $true
            }
        }

        if (-not $hasDuration) {
            Write-Warning "Metric object missing DurationMs property. Skipping."
            continue
        }

        $validatedMetrics.Add($metric)
    }

    if ($validatedMetrics.Count -eq 0) {
        return [PSCustomObject]@{
            OperationName     = $OperationName
            Count             = 0
            TotalDurationMs   = 0
            AverageDurationMs = 0
            MinDurationMs     = 0
            MaxDurationMs     = 0
            SuccessCount      = 0
            FailureCount      = 0
            SuccessRate       = 0
        }
    }

    $durations = foreach ($metric in $validatedMetrics) {
        if ($metric -is [System.Collections.IDictionary]) {
            $metric['DurationMs']
        }
        else {
            $metric.DurationMs
        }
    }

    $successCount = 0
    $failureCount = 0

    foreach ($metric in $validatedMetrics) {
        $successValue = if ($metric -is [System.Collections.IDictionary]) {
            $metric['Success']
        }
        else {
            $metric.PSObject.Properties['Success']?.Value
        }

        if ($successValue -eq $true) {
            $successCount++
        }
        elseif ($successValue -eq $false) {
            $failureCount++
        }
    }

    $durationList = @()
    foreach ($value in $durations) {
        if ($null -ne $value -and ($value -is [double] -or $value -is [int] -or $value -is [long])) {
            $durationList += [double]$value
        }
    }
    $sortedDurations = $durationList | Sort-Object
    $count = $sortedDurations.Count

    return [PSCustomObject]@{
        OperationName     = $OperationName
        Count             = $validatedMetrics.Count
        TotalDurationMs   = if ($durationList.Count -gt 0) { [math]::Round(($durationList | Measure-Object -Sum).Sum, 2) } else { 0 }
        AverageDurationMs = if ($count -gt 0) { [math]::Round(($durationList | Measure-Object -Average).Average, 2) } else { 0 }
        MinDurationMs     = if ($count -gt 0) { [math]::Round(($sortedDurations | Measure-Object -Minimum).Minimum, 2) } else { 0 }
        MaxDurationMs     = if ($count -gt 0) { [math]::Round(($sortedDurations | Measure-Object -Maximum).Maximum, 2) } else { 0 }
        MedianDurationMs  = if ($count -gt 0) {
            $medianIndex = [math]::Floor($count / 2)
            if ($count % 2 -eq 0) {
                [math]::Round(($sortedDurations[$medianIndex - 1] + $sortedDurations[$medianIndex]) / 2, 2)
            }
            else {
                [math]::Round($sortedDurations[$medianIndex], 2)
            }
        }
        else { 0 }
        P50DurationMs     = if ($count -gt 0) { [math]::Round($sortedDurations[[math]::Floor($count * 0.5)], 2) } else { 0 }
        P95DurationMs     = if ($count -gt 0) { [math]::Round($sortedDurations[[math]::Floor($count * 0.95)], 2) } else { 0 }
        P99DurationMs     = if ($count -gt 0) { [math]::Round($sortedDurations[[math]::Floor($count * 0.99)], 2) } else { 0 }
        SuccessCount      = $successCount
        FailureCount      = $failureCount
        SuccessRate       = if ($Metrics.Count -gt 0) { [math]::Round(($successCount / $Metrics.Count) * 100, 2) } else { 0 }
    }
}

# Export functions
Export-ModuleMember -Function @(
    'Measure-Operation',
    'Test-PerformanceRegression',
    'Get-AggregatedMetrics'
)

