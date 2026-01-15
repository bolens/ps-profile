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
        [ValidateNotNullOrEmpty()]
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
        # Optimized: Use foreach loop instead of ForEach-Object
        foreach ($prop in $CurrentMetrics.PSObject.Properties) {
            $hash[$prop.Name] = $prop.Value
        }
        $hash
    }
    else {
        throw "CurrentMetrics must be a Hashtable or PSCustomObject. Received type: $($CurrentMetrics.GetType().Name)"
    }

    if ($metricsHash.Count -eq 0) {
        if (Get-Command Write-StructuredWarning -ErrorAction SilentlyContinue) {
            Write-StructuredWarning -Message "CurrentMetrics is empty" -OperationName 'performance-regression.test' -Context @{
                baseline_file  = $BaselineFile
                operation_name = $OperationName
            } -Code 'EmptyMetrics'
        }
        else {
            $debugLevel = 0
            if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel)) {
                if ($debugLevel -ge 1) {
                    Write-Warning "[performance-regression.test] CurrentMetrics is empty. No metrics to compare."
                }
                # Level 3: Log detailed empty metrics information
                if ($debugLevel -ge 3) {
                    Write-Verbose "[performance-regression.test] Empty metrics details - OperationName: $OperationName, BaselineFile: $BaselineFile"
                }
            }
            else {
                # Always log warnings even if debug is off
                if (Get-Command Write-StructuredWarning -ErrorAction SilentlyContinue) {
                    Write-StructuredWarning -Message "CurrentMetrics is empty" -OperationName 'performance-regression.test' -Context @{
                        # Technical context
                        baseline_file  = $BaselineFile
                        operation_name = $OperationName
                        # Invocation context
                        FunctionName   = 'Test-PerformanceRegression'
                    } -Code 'EmptyMetrics'
                }
                else {
                    Write-Warning "[performance-regression.test] CurrentMetrics is empty. No metrics to compare."
                }
            }
        }
    }

    $regressionDetected = $false
    $regressions = [System.Collections.Generic.List[PSCustomObject]]::new()

    if (-not (Test-Path -Path $BaselineFile)) {
        $debugLevel = 0
        if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel) -and $debugLevel -ge 2) {
            Write-Host "  [performance-regression.test] Baseline file not found: $BaselineFile" -ForegroundColor DarkGray
        }
        return [PSCustomObject]@{
            RegressionDetected = $false
            Ratio              = 1.0
            Details            = @()
            Message            = "No baseline found"
        }
    }

    try {
        $debugLevel = 0
        if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel) -and $debugLevel -ge 2) {
            Write-Verbose "[performance-regression.test] Loading baseline from: $BaselineFile"
        }
        
        $baseline = Get-Content -Path $BaselineFile -Raw | ConvertFrom-Json
        
        $debugLevel = 0
        if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel) -and $debugLevel -ge 3) {
            Write-Host "  [performance-regression.test] Comparing $($metricsHash.Count) metrics against baseline" -ForegroundColor DarkGray
        }

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
                        $debugLevel = 0
                        if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel) -and $debugLevel -ge 3) {
                            Write-Verbose "[performance-regression.test] Regression detected for $key : Current=$currentValue, Baseline=$baselineValue, Ratio=$([math]::Round($ratio, 2))"
                        }
                    }
                    elseif ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel) -and $debugLevel -ge 3) {
                        Write-Verbose "[performance-regression.test] Metric $key within threshold: Ratio=$([math]::Round($ratio, 2))"
                    }
                }
            }
        }
    }
    catch {
        if (Get-Command Write-StructuredWarning -ErrorAction SilentlyContinue) {
            Write-StructuredWarning -Message "Failed to load baseline" -OperationName 'performance-regression.test' -Context @{
                baseline_file  = $BaselineFile
                operation_name = $OperationName
                error_message  = $_.Exception.Message
            } -Code 'BaselineLoadFailed'
        }
        else {
            $debugLevel = 0
            if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel)) {
                if ($debugLevel -ge 1) {
                    Write-Warning "[performance-regression.test] Failed to load baseline: $($_.Exception.Message)"
                }
                # Level 3: Log detailed baseline load error information
                if ($debugLevel -ge 3) {
                    Write-Host "  [performance-regression.test] Baseline load error details - BaselineFile: $BaselineFile, OperationName: $OperationName, Exception: $($_.Exception.GetType().FullName), Message: $($_.Exception.Message), Stack: $($_.ScriptStackTrace)" -ForegroundColor DarkGray
                }
            }
            else {
                # Always log warnings even if debug is off
                if (Get-Command Write-StructuredWarning -ErrorAction SilentlyContinue) {
                    Write-StructuredWarning -Message "Failed to load baseline" -OperationName 'performance-regression.test' -Context @{
                        # Technical context
                        baseline_file  = $BaselineFile
                        operation_name = $OperationName
                        # Error context
                        error_message  = $_.Exception.Message
                        ErrorType      = $_.Exception.GetType().FullName
                        # Invocation context
                        FunctionName   = 'Test-PerformanceRegression'
                    } -Code 'BaselineLoadFailed'
                }
                else {
                    Write-Warning "[performance-regression.test] Failed to load baseline: $($_.Exception.Message)"
                }
            }
        }
        return [PSCustomObject]@{
            RegressionDetected = $false
            Ratio              = 1.0
            Details            = @()
            Message            = "Error loading baseline: $($_.Exception.Message)"
        }
        
        $debugLevel = 0
        if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel) -and $debugLevel -ge 2) {
            Write-Verbose "[performance-regression.test] Regression test complete: RegressionDetected=$regressionDetected, RegressionsFound=$($regressions.Count)"
        }
    }

    return [PSCustomObject]@{
        RegressionDetected = $regressionDetected
        Ratio              = if ($regressions.Count -gt 0) { ($regressions | Measure-Object -Property Ratio -Maximum).Maximum } else { 1.0 }
        Details            = [object[]]$regressions.ToArray()
        OperationName      = $OperationName
    }
}

Export-ModuleMember -Function Test-PerformanceRegression

