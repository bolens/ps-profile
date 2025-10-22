<#
scripts/benchmark-startup.ps1

Measures interactive PowerShell startup performance and per-fragment dot-source times.

Outputs a simple CSV and a human-readable table. Designed to run on Windows pwsh.

Usage: pwsh -NoProfile -File scripts\benchmark-startup.ps1
#>

param(
    [int]$Iterations = 5,
    [string]$WorkspaceRoot = (Split-Path -Parent $PSScriptRoot),
    [switch]$UpdateBaseline,
    [double]$RegressionThreshold = 1.5  # Allow 50% degradation before failing
)

function Time-Command {
    param([scriptblock]$Script)
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    & $Script
    $sw.Stop()
    return $sw.Elapsed.TotalMilliseconds
}

# Ensure we run from repository root
Push-Location $WorkspaceRoot

# 1) Measure full interactive startup: spawn pwsh that dot-sources the main profile
# Create a temporary child script that dot-sources the profile and writes a marker.
$fullResults = [System.Collections.Generic.List[double]]::new()
for ($i = 1; $i -le $Iterations; $i++) {
    $marker = "PS_STARTUP_READY_$([guid]::NewGuid().ToString('N'))"
    $profilePath = Join-Path $WorkspaceRoot 'Microsoft.PowerShell_profile.ps1'
    $tempFull = [System.IO.Path]::Combine([System.IO.Path]::GetTempPath(), "ps_profile_startup_$([guid]::NewGuid().ToString('N')).ps1")
    $childScript = @"
. '$($profilePath)'
Write-Output '$($marker)'
"@
    Set-Content -Path $tempFull -Value $childScript -Encoding UTF8

    $startInfo = New-Object System.Diagnostics.ProcessStartInfo
    $startInfo.FileName = 'pwsh'
    # Use -NoProfile -File to avoid complex quoting of -Command
    $startInfo.Arguments = "-NoProfile -File `"$tempFull`""
    $startInfo.RedirectStandardOutput = $true
    $startInfo.RedirectStandardError = $true
    $startInfo.UseShellExecute = $false
    $startInfo.CreateNoWindow = $true

    $proc = New-Object System.Diagnostics.Process
    $proc.StartInfo = $startInfo

    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    $proc.Start() | Out-Null

    # Read output until marker or timeout
    $out = ''
    while (-not $proc.HasExited -and $sw.Elapsed.TotalSeconds -lt 30) {
        Start-Sleep -Milliseconds 50
        while (-not $proc.StandardOutput.EndOfStream) { $line = $proc.StandardOutput.ReadLine(); $out += "$line`n"; if ($line -eq $marker) { break } }
        if ($out -match [regex]::Escape($marker)) { break }
    }
    $sw.Stop()
    $ms = $sw.Elapsed.TotalMilliseconds
    $fullResults.Add($ms)
    try {
        $proc.Kill()
    } catch {
        # ignore any errors when killing the process
    } finally {
        Remove-Item -Path $tempFull -Force -ErrorAction SilentlyContinue
    }
}

# 2) Measure per-fragment dot-source time: run a fresh pwsh -NoProfile that dot-sources a single fragment
$fragments = Get-ChildItem -Path (Join-Path $WorkspaceRoot 'profile.d') -Filter '*.ps1' | Sort-Object Name
$fragmentResults = @()
foreach ($frag in $fragments) {
    $times = [System.Collections.Generic.List[double]]::new()
    for ($i = 1; $i -le $Iterations; $i++) {
        $scriptPath = $frag.FullName
        $tempFrag = [System.IO.Path]::Combine([System.IO.Path]::GetTempPath(), "ps_profile_frag_$([guid]::NewGuid().ToString('N')).ps1")
        $child = @"
`$sw = [System.Diagnostics.Stopwatch]::StartNew()
. '$($scriptPath)'
`$sw.Stop()
Write-Output `$sw.Elapsed.TotalMilliseconds
"@
        Set-Content -Path $tempFrag -Value $child -Encoding UTF8

        $startInfo = New-Object System.Diagnostics.ProcessStartInfo
        $startInfo.FileName = 'pwsh'
        $startInfo.Arguments = "-NoProfile -File `"$tempFrag`""
        $startInfo.RedirectStandardOutput = $true
        $startInfo.RedirectStandardError = $true
        $startInfo.UseShellExecute = $false
        $startInfo.CreateNoWindow = $true

        $proc = New-Object System.Diagnostics.Process
        $proc.StartInfo = $startInfo
        $proc.Start() | Out-Null
        $out = $proc.StandardOutput.ReadToEnd()
        $proc.WaitForExit(10000) | Out-Null
        [double]$val = 0
        if ($out -match '(\d+\.?\d*)') { [double]$val = [double]$matches[1] }
        $times.Add($val)
        Remove-Item -Path $tempFrag -Force -ErrorAction SilentlyContinue
    }
    $fragmentResults += [PSCustomObject]@{
        Fragment = $frag.Name
        Iterations = $Iterations
        MeanMs = [Math]::Round(($times | Measure-Object -Average).Average,2)
        MedianMs = [Math]::Round((($times | Sort-Object)[$times.Count/2]),2)
        Raw = $times -join ','
    }
}

# Print results
Write-Output "\nStartup benchmark (ms) - iterations: $Iterations"
$fullResultsArray = $fullResults.ToArray()
$currentMean = [Math]::Round(($fullResultsArray | Measure-Object -Average).Average,2)
Write-Output "Full startup times (ms): $($fullResultsArray -join ',')"
Write-Output "Full startup mean (ms): $currentMean"

Write-Output "\nPer-fragment dot-source timings (ms):"
$fragmentResults | Sort-Object -Property MeanMs -Descending | Format-Table -AutoSize

# Performance regression detection
$baselineFile = Join-Path $WorkspaceRoot 'scripts' 'data' 'performance-baseline.json'
$regressionDetected = $false

if (Test-Path $baselineFile) {
    Write-Output "`nPerformance Regression Check:"
    try {
        $baseline = Get-Content $baselineFile -Raw | ConvertFrom-Json

        # Check full startup time regression
        $baselineMean = $baseline.FullStartupMean
        $ratio = $currentMean / $baselineMean
        Write-Output "Full startup: Current=$currentMean ms, Baseline=$baselineMean ms, Ratio=$([Math]::Round($ratio,2))x"

        if ($ratio -gt $RegressionThreshold) {
            Write-Warning "PERFORMANCE REGRESSION: Full startup time increased by $([Math]::Round(($ratio-1)*100,1))% (threshold: $([Math]::Round(($RegressionThreshold-1)*100,1))%)"
            $regressionDetected = $true
        }

        # Check per-fragment regressions
        foreach ($frag in $fragmentResults) {
            $baselineFrag = $baseline.Fragments | Where-Object { $_.Fragment -eq $frag.Fragment }
            if ($baselineFrag) {
                $fragRatio = $frag.MeanMs / $baselineFrag.MeanMs
                if ($fragRatio -gt $RegressionThreshold) {
                    Write-Warning "PERFORMANCE REGRESSION: $($frag.Fragment) increased by $([Math]::Round(($fragRatio-1)*100,1))% (current: $($frag.MeanMs)ms, baseline: $($baselineFrag.MeanMs)ms)"
                    $regressionDetected = $true
                }
            }
        }

        if (-not $regressionDetected) {
            Write-Output "✓ No performance regressions detected"
        }
    } catch {
        Write-Warning "Failed to load or parse baseline file: $($_.Exception.Message)"
    }
} else {
    Write-Output "`nNo baseline performance data found. Run with -UpdateBaseline to create baseline."
}

# Save new baseline if requested
if ($UpdateBaseline) {
    $baselineData = @{
        Timestamp = (Get-Date).ToString('o')
        FullStartupMean = $currentMean
        FullStartupRaw = $fullResultsArray
        Fragments = $fragmentResults | ForEach-Object {
            @{
                Fragment = $_.Fragment
                MeanMs = $_.MeanMs
                MedianMs = $_.MedianMs
                Raw = $_.Raw
            }
        }
    }

    $baselineData | ConvertTo-Json -Depth 10 | Set-Content $baselineFile -Encoding UTF8
    Write-Output "`nUpdated performance baseline: $baselineFile"
}

# Save CSV
$csvOut = Join-Path $WorkspaceRoot 'scripts' 'data' 'startup-benchmark.csv'
$fragmentResults | Export-Csv -Path $csvOut -NoTypeInformation -Force
Write-Output "`nSaved per-fragment results to: $csvOut"

# Exit with error if regression detected (unless updating baseline)
if ($regressionDetected -and -not $UpdateBaseline) {
    Write-Error "Performance regression detected. Use -UpdateBaseline to accept new performance baseline."
    Pop-Location
    exit 1
}

Pop-Location
