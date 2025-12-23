# ===============================================
# ProfileFragmentTiming.psm1
# Fragment load time measurement and tracking
# ===============================================

<#
.SYNOPSIS
    Initializes fragment timing tracking.
.DESCRIPTION
    Sets up global list for tracking fragment load times.
#>
function Initialize-FragmentTiming {
    [CmdletBinding()]
    param()

    if ($env:PS_PROFILE_DEBUG -and -not $global:PSProfileFragmentTimes) {
        $global:PSProfileFragmentTimes = [System.Collections.Generic.List[PSCustomObject]]::new()
    }
}

<#
.SYNOPSIS
    Measures and tracks the execution time of profile fragments.
.DESCRIPTION
    Wraps the execution of profile fragments to measure their load time.
    Supports granular debug levels:
    - PS_PROFILE_DEBUG=1: Basic debug (current behavior)
    - PS_PROFILE_DEBUG=2: Verbose debug (includes timing)
    - PS_PROFILE_DEBUG=3: Performance profiling (detailed metrics)
    Results are stored in a global list for later analysis.
.PARAMETER FragmentName
    The name of the fragment being measured.
.PARAMETER Action
    The script block to execute and measure.
#>
function Measure-FragmentLoadTime {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$FragmentName,
        
        [Parameter(Mandatory)]
        [scriptblock]$Action
    )

    # Parse debug level: 0=off, 1=basic, 2=with timing, 3=verbose timing output
    $debugLevel = 0
    if ($env:PS_PROFILE_DEBUG) {
        if (-not [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel)) {
            # Non-numeric value defaults to basic debug
            $debugLevel = 1
        }
    }

    if ($debugLevel -eq 0) {
        & $Action
        return
    }

    # Level 2+: measure and track execution time
    if ($debugLevel -ge 2) {
        $sw = [System.Diagnostics.Stopwatch]::StartNew()
        try {
            & $Action
        }
        finally {
            $sw.Stop()
            $timing = [PSCustomObject]@{
                Fragment  = $FragmentName
                Duration  = $sw.Elapsed.TotalMilliseconds
                Timestamp = [DateTime]::Now
            }

            if (-not $global:PSProfileFragmentTimes) {
                $global:PSProfileFragmentTimes = [System.Collections.Generic.List[PSCustomObject]]::new()
            }
            $global:PSProfileFragmentTimes.Add($timing)

            # Level 3: display timing information immediately
            if ($debugLevel -ge 3) {
                # Use locale-aware number formatting if available
                $durationStr = if (Get-Command Format-LocaleNumber -ErrorAction SilentlyContinue) {
                    Format-LocaleNumber $timing.Duration -Format 'N0'
                }
                else {
                    $timing.Duration.ToString("N0")
                }
                Write-Host "Fragment '$FragmentName' loaded in ${durationStr}ms" -ForegroundColor Cyan
            }
        }
    }
    else {
        # Level 1: basic debug without timing
        & $Action
    }
}

Export-ModuleMember -Function 'Initialize-FragmentTiming', 'Measure-FragmentLoadTime'
