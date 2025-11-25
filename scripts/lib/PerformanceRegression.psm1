<#
scripts/lib/PerformanceRegression.psm1

.SYNOPSIS
    Performance regression detection utilities.

.DESCRIPTION
    Provides functions for detecting performance regressions by comparing metrics against baselines.
#>

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

Export-ModuleMember -Function Test-PerformanceRegression

