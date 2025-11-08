<#
scripts/utils/benchmark-startup.ps1

.SYNOPSIS
    Measures interactive PowerShell startup performance and per-fragment dot-source times.

.DESCRIPTION
    Measures interactive PowerShell startup performance and per-fragment dot-source times.
    Outputs a simple CSV and a human-readable table. Designed to run on Windows pwsh.

.EXAMPLE
    pwsh -NoProfile -File scripts\utils\benchmark-startup.ps1
    pwsh -NoProfile -File scripts\utils\benchmark-startup.ps1 -Iterations 10
    pwsh -NoProfile -File scripts\utils\benchmark-startup.ps1 -UpdateBaseline
    pwsh -NoProfile -File scripts\utils\benchmark-startup.ps1 -RegressionThreshold 1.2
    pwsh -NoProfile -File scripts\utils\benchmark-startup.ps1 -WorkspaceRoot C:\Users\username\Documents\PowerShell\profile
    pwsh -NoProfile -File scripts\utils\benchmark-startup.ps1 -Iterations 5 -UpdateBaseline -RegressionThreshold 1.2 -WorkspaceRoot C:\Users\username\Documents\PowerShell\profile

.PARAMETER Iterations
    The number of times to run the benchmark.
.PARAMETER WorkspaceRoot
    The root directory of the workspace.
.PARAMETER UpdateBaseline
    Update the performance baseline.
.PARAMETER RegressionThreshold
    The threshold for performance regression.
#>

param(
    [ValidateScript({
            if ($_ -le 0) {
                throw "Iterations must be a positive integer. Value provided: $_"
            }
            $true
        })]
    [int]$Iterations = 5,

    [ValidateScript({
            if ($_ -and -not (Test-Path $_ -PathType Container)) {
                throw "WorkspaceRoot must be a valid directory path. Path provided: $_"
            }
            $true
        })]
    [string]$WorkspaceRoot = $null,

    [switch]$UpdateBaseline,

    [ValidateScript({
            if ($_ -le 0) {
                throw "RegressionThreshold must be a positive number. Value provided: $_"
            }
            $true
        })]
    [double]$RegressionThreshold = 1.5  # Allow 50% degradation before failing
)

# Import shared utilities
$commonModulePath = Join-Path $PSScriptRoot 'Common.psm1'
Import-Module $commonModulePath -ErrorAction Stop

# Get repository root if not specified
if (-not $WorkspaceRoot) {
    try {
        $WorkspaceRoot = Get-RepoRoot -ScriptPath $PSScriptRoot
    }
    catch {
        Exit-WithCode -ExitCode $EXIT_SETUP_ERROR -ErrorRecord $_
    }
}

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

    $startInfo = New-Object System.Diagnostics.ProcessStartInfo
    $startInfo.FileName = Get-PowerShellExecutable
    $startInfo.Arguments = "-NoProfile -Command `"$env:PS_PROFILE_AUTOENABLE_PSREADLINE = '1'; Import-Module PSReadLine -ErrorAction SilentlyContinue; . '$($profilePath)'; Write-Output '$($marker)'`""
    $startInfo.RedirectStandardOutput = $true
    $startInfo.RedirectStandardError = $true
    $startInfo.UseShellExecute = $false
    $startInfo.CreateNoWindow = $true

    $proc = New-Object System.Diagnostics.Process
    $proc.StartInfo = $startInfo

    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    $proc.Start() | Out-Null

    # Compile regex pattern once for marker detection
    $markerRegex = [regex]::new([regex]::Escape($marker), [System.Text.RegularExpressions.RegexOptions]::Compiled)
    
    # Read output until marker or timeout
    # Use StringBuilder for better performance than string concatenation in loop
    $outBuilder = [System.Text.StringBuilder]::new()
    while (-not $proc.HasExited -and $sw.Elapsed.TotalSeconds -lt 30) {
        Start-Sleep -Milliseconds 50
        while (-not $proc.StandardOutput.EndOfStream) { 
            $line = $proc.StandardOutput.ReadLine()
            [void]$outBuilder.AppendLine($line)
            if ($line -eq $marker) { break } 
        }
        $out = $outBuilder.ToString()
        if ($markerRegex.IsMatch($out)) { break }
    }
    $sw.Stop()
    $ms = $sw.Elapsed.TotalMilliseconds
    $fullResults.Add($ms)
    try {
        $proc.Kill()
    }
    catch {
        # ignore any errors when killing the process
    }
}

# 2) Measure per-fragment dot-source time: run a fresh pwsh -NoProfile that dot-sources a single fragment
# Compile regex pattern once for extracting numeric values (used in loop)
$numericRegex = [regex]::new('(\d+\.?\d*)', [System.Text.RegularExpressions.RegexOptions]::Compiled)

$fragments = Get-ChildItem -Path (Join-Path $WorkspaceRoot 'profile.d') -Filter '*.ps1' | Sort-Object Name
# Use List for better performance than array concatenation
$fragmentResults = [System.Collections.Generic.List[PSCustomObject]]::new()
foreach ($frag in $fragments) {
    $times = [System.Collections.Generic.List[double]]::new()
    for ($i = 1; $i -le $Iterations; $i++) {
        $scriptPath = $frag.FullName
        $tempFrag = [System.IO.Path]::Combine([System.IO.Path]::GetTempPath(), "ps_profile_frag_$([guid]::NewGuid().ToString('N')).ps1")
        $child = @"
$env:PS_PROFILE_AUTOENABLE_PSREADLINE = '1'
Import-Module PSReadLine -ErrorAction SilentlyContinue
`$sw = [System.Diagnostics.Stopwatch]::StartNew()
. '$($scriptPath)'
`$sw.Stop()
Write-Output `$sw.Elapsed.TotalMilliseconds
"@
        Set-Content -Path $tempFrag -Value $child -Encoding UTF8

        $startInfo = New-Object System.Diagnostics.ProcessStartInfo
        $startInfo.FileName = Get-PowerShellExecutable
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
        $match = $numericRegex.Match($out)
        if ($match.Success) { [double]$val = [double]$match.Groups[1].Value }
        $times.Add($val)
        Remove-Item -Path $tempFrag -Force -ErrorAction SilentlyContinue
    }
    $fragmentResults.Add([PSCustomObject]@{
            Fragment   = $frag.Name
            Iterations = $Iterations
            MeanMs     = [Math]::Round(($times | Measure-Object -Average).Average, 2)
            MedianMs   = [Math]::Round((($times | Sort-Object)[$times.Count / 2]), 2)
            Raw        = $times -join ','
        })
}

# Print results
Write-ScriptMessage -Message "Startup benchmark (ms) - iterations: $Iterations"
$fullResultsArray = $fullResults.ToArray()
$currentMean = [Math]::Round(($fullResultsArray | Measure-Object -Average).Average, 2)
Write-ScriptMessage -Message "Full startup times (ms): $($fullResultsArray -join ',')"
Write-ScriptMessage -Message "Full startup mean (ms): $currentMean"

Write-ScriptMessage -Message "Per-fragment dot-source timings (ms):"
$fragmentResults | Sort-Object -Property MeanMs -Descending | Format-Table -AutoSize

# Performance regression detection
$baselineFile = Join-Path $WorkspaceRoot 'scripts' 'data' 'performance-baseline.json'
$regressionDetected = $false

if (Test-Path $baselineFile) {
    Write-ScriptMessage -Message "`nPerformance Regression Check:"
    try {
        $baseline = Get-Content $baselineFile -Raw | ConvertFrom-Json

        # Check full startup time regression
        $baselineMean = $baseline.FullStartupMean
        $ratio = $currentMean / $baselineMean
        Write-ScriptMessage -Message "Full startup: Current=$currentMean ms, Baseline=$baselineMean ms, Ratio=$([Math]::Round($ratio,2))x"

        if ($ratio -gt $RegressionThreshold) {
            Write-ScriptMessage -Message "PERFORMANCE REGRESSION: Full startup time increased by $([Math]::Round(($ratio-1)*100,1))% (threshold: $([Math]::Round(($RegressionThreshold-1)*100,1))%)" -IsWarning
            $regressionDetected = $true
        }

        # Check per-fragment regressions
        foreach ($frag in $fragmentResults) {
            $baselineFrag = $baseline.Fragments | Where-Object { $_.Fragment -eq $frag.Fragment }
            if ($baselineFrag) {
                $fragRatio = $frag.MeanMs / $baselineFrag.MeanMs
                if ($fragRatio -gt $RegressionThreshold) {
                    Write-ScriptMessage -Message "PERFORMANCE REGRESSION: $($frag.Fragment) increased by $([Math]::Round(($fragRatio-1)*100,1))% (current: $($frag.MeanMs)ms, baseline: $($baselineFrag.MeanMs)ms)" -IsWarning
                    $regressionDetected = $true
                }
            }
        }

        if (-not $regressionDetected) {
            Write-ScriptMessage -Message "✓ No performance regressions detected"
        }
    }
    catch {
        Write-ScriptMessage -Message "Failed to load or parse baseline file: $($_.Exception.Message)" -IsWarning
    }
}
else {
    Write-ScriptMessage -Message "`nNo baseline performance data found. Run with -UpdateBaseline to create baseline."
}

# Save new baseline if requested
if ($UpdateBaseline) {
    $baselineData = @{
        Timestamp       = (Get-Date).ToString('o')
        FullStartupMean = $currentMean
        FullStartupRaw  = $fullResultsArray
        Fragments       = $fragmentResults | ForEach-Object {
            @{
                Fragment = $_.Fragment
                MeanMs   = $_.MeanMs
                MedianMs = $_.MedianMs
                Raw      = $_.Raw
            }
        }
    }

    $baselineData | ConvertTo-Json -Depth 10 | Set-Content $baselineFile -Encoding UTF8
    Write-ScriptMessage -Message "`nUpdated performance baseline: $baselineFile"
}

# Save CSV - ensure data directory exists
$dataDir = Join-Path $WorkspaceRoot 'scripts' 'data'
try {
    Ensure-DirectoryExists -Path $dataDir
}
catch {
    Exit-WithCode -ExitCode $EXIT_SETUP_ERROR -ErrorRecord $_
}

$csvOut = Join-Path $dataDir 'startup-benchmark.csv'
$fragmentResults | Export-Csv -Path $csvOut -NoTypeInformation -Force
Write-ScriptMessage -Message "`nSaved per-fragment results to: $csvOut"

# Exit with error if regression detected (unless updating baseline)
if ($regressionDetected -and -not $UpdateBaseline) {
    Pop-Location
    Exit-WithCode -ExitCode $EXIT_VALIDATION_FAILURE -Message "Performance regression detected. Use -UpdateBaseline to accept new performance baseline."
}

Pop-Location
Exit-WithCode -ExitCode $EXIT_SUCCESS -Message "Benchmark completed successfully"
