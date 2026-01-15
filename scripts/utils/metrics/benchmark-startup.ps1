<#
scripts/utils/benchmark-startup.ps1

.SYNOPSIS
    Measures interactive PowerShell startup performance and per-fragment dot-source times.

.DESCRIPTION
    Measures interactive PowerShell startup performance and per-fragment dot-source times.
    Outputs a simple CSV and a human-readable table. Cross-platform compatible.

.EXAMPLE
    pwsh -NoProfile -File scripts/utils/benchmark-startup.ps1
    pwsh -NoProfile -File scripts/utils/benchmark-startup.ps1 -Iterations 10
    pwsh -NoProfile -File scripts/utils/benchmark-startup.ps1 -UpdateBaseline
    pwsh -NoProfile -File scripts/utils/benchmark-startup.ps1 -RegressionThreshold 1.2
    pwsh -NoProfile -File scripts/utils/benchmark-startup.ps1 -WorkspaceRoot /home/username/Documents/PowerShell
    pwsh -NoProfile -File scripts/utils/benchmark-startup.ps1 -Iterations 5 -UpdateBaseline -RegressionThreshold 1.2 -WorkspaceRoot /home/username/Documents/PowerShell

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

# Import shared utilities directly (no barrel files)
# Import PathResolution first (needed by ModuleImport)
$libRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$pathResolutionPath = Join-Path $libRoot 'lib' 'path' 'PathResolution.psm1'
if ($pathResolutionPath -and (Test-Path -LiteralPath $pathResolutionPath)) {
    Import-Module $pathResolutionPath -DisableNameChecking -ErrorAction Stop
}

# Import ModuleImport (bootstrap)
$moduleImportPath = Join-Path $libRoot 'lib' 'ModuleImport.psm1'
Import-Module $moduleImportPath -DisableNameChecking -ErrorAction Stop

# Parse debug level once at script start
$debugLevel = 0
if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel)) {
    # Debug is enabled, $debugLevel contains the numeric level (1-3)
}

# Import shared utilities using ModuleImport (with -Global to ensure functions are available)
Import-LibModule -ModuleName 'ExitCodes' -ScriptPath $PSScriptRoot -DisableNameChecking -Global
Import-LibModule -ModuleName 'Logging' -ScriptPath $PSScriptRoot -DisableNameChecking -Global
Import-LibModule -ModuleName 'Locale' -ScriptPath $PSScriptRoot -DisableNameChecking -Global
Import-LibModule -ModuleName 'JsonUtilities' -ScriptPath $PSScriptRoot -DisableNameChecking -Global
Import-LibModule -ModuleName 'PowerShellDetection' -ScriptPath $PSScriptRoot -DisableNameChecking -Global

# Resolve workspace root
if (-not $WorkspaceRoot) {
    try {
        $WorkspaceRoot = Get-RepoRoot -ScriptPath $PSScriptRoot
    }
    catch {
        if (Get-Command Exit-WithCode -ErrorAction SilentlyContinue) {
            Exit-WithCode -ExitCode [ExitCode]::SetupError -ErrorRecord $_
        }
        else {
            if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                Write-StructuredError -ErrorRecord $_ -OperationName 'benchmark.startup.setup' -Context @{
                    workspace_root = $WorkspaceRoot
                }
            }
            else {
                Write-Error "Failed to resolve workspace root: $($_.Exception.Message)"
            }
            exit 2
        }
    }
}

<#
.SYNOPSIS
    Measures the execution time of a scriptblock.

.DESCRIPTION
    Executes a scriptblock and returns the elapsed time in milliseconds.
    Uses System.Diagnostics.Stopwatch for high-precision timing.

.PARAMETER Script
    The scriptblock to execute and measure.

.OUTPUTS
    System.Double. The elapsed time in milliseconds.

.EXAMPLE
    $duration = Time-Command -Script { Get-Process }
    Write-Output "Operation took $duration ms"
#>
function Time-Command {
    [CmdletBinding()]
    [OutputType([double])]
    param(
        [Parameter(Mandatory)]
        [scriptblock]$Script
    )
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    & $Script
    $sw.Stop()
    return $sw.Elapsed.TotalMilliseconds
}

# Ensure we run from repository root
Push-Location $WorkspaceRoot

# Level 1: Basic operation start
if ($debugLevel -ge 1) {
    Write-Verbose "[benchmark.startup] Starting startup benchmark"
    Write-Verbose "[benchmark.startup] Iterations: $Iterations, Workspace root: $WorkspaceRoot"
    Write-Verbose "[benchmark.startup] Update baseline: $UpdateBaseline, Regression threshold: $RegressionThreshold"
}

# 1) Measure full interactive startup: spawn pwsh that dot-sources the main profile
# Create a temporary child script that dot-sources the profile and writes a marker.
$fullResults = [System.Collections.Generic.List[double]]::new()
$fullStartupFailed = 0

# Level 1: Full startup measurement start
if ($debugLevel -ge 1) {
    Write-Verbose "[benchmark.startup] Starting full profile startup measurement"
}

Write-ScriptMessage -Message "Measuring full profile startup ($Iterations iterations)..." -LogLevel Info
$fullStartupStartTime = Get-Date
for ($i = 1; $i -le $Iterations; $i++) {
    # Level 1: Individual iteration
    if ($debugLevel -ge 1) {
        Write-Verbose "[benchmark.startup] Full startup iteration $i/$Iterations"
    }
    Write-ScriptMessage -Message "  Iteration $i/$Iterations..." -LogLevel Debug
    try {
        $marker = "PS_STARTUP_READY_$([guid]::NewGuid().ToString('N'))"
        $profilePath = Join-Path $WorkspaceRoot 'Microsoft.PowerShell_profile.ps1'

        $startInfo = New-Object System.Diagnostics.ProcessStartInfo
        $startInfo.FileName = Get-PowerShellExecutable
        # Use minimal environment for faster benchmark execution
        $startInfo.Arguments = "-NoProfile -Command `"`$env:PS_PROFILE_ENVIRONMENT = 'minimal'; `$env:PS_PROFILE_AUTOENABLE_PSREADLINE = '1'; Import-Module PSReadLine -ErrorAction SilentlyContinue; . '$($profilePath)'; Write-Output '$($marker)'`""
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
        
        # Simplified approach: Wait for process with timeout, then read all output
        # This avoids deadlocks from buffered output and complexity of async reading
        $timeoutSeconds = 120  # 2 minutes timeout for profile loading
        $timeoutMs = $timeoutSeconds * 1000
        $markerFound = $false
        
        # Wait for process to exit with timeout
        if (-not $proc.WaitForExit($timeoutMs)) {
            # Process didn't exit within timeout
            Write-ScriptMessage -Message "Profile load timed out after $timeoutSeconds seconds (iteration $i), killing process..." -IsWarning
            try {
                $proc.Kill()
                $proc.WaitForExit(5000) | Out-Null
            }
            catch {
                Write-ScriptMessage -Message "Failed to kill process: $_" -IsWarning
            }
        }
        
        $sw.Stop()
        
        # Read all output after process exits (or was killed)
        $allOutput = $null
        try {
            $allOutput = $proc.StandardOutput.ReadToEnd()
            if ($allOutput) {
                $markerFound = $markerRegex.IsMatch($allOutput)
            }
        }
        catch {
            Write-ScriptMessage -Message "Failed to read output: $_" -IsWarning
        }
        
        # Read error output if marker not found
        if (-not $markerFound) {
            try {
                $errorOutput = $proc.StandardError.ReadToEnd()
                if ($errorOutput) {
                    Write-ScriptMessage -Message "Profile load completed but marker not found (iteration $i). Error output: $errorOutput" -IsWarning
                }
            }
            catch {
                # Ignore errors reading error output
            }
        }
        
        $ms = $sw.Elapsed.TotalMilliseconds
        $fullResults.Add($ms)
        
        # Output timing for this iteration
        $formattedMs = if (Get-Command Format-LocaleNumber -ErrorAction SilentlyContinue) {
            Format-LocaleNumber ([Math]::Round($ms, 2)) -Format 'N2'
        }
        else {
            [Math]::Round($ms, 2).ToString("N2")
        }
        Write-ScriptMessage -Message "  Iteration $($i)/$($Iterations): $($formattedMs) ms" -LogLevel Info
    }
    catch {
        $fullStartupFailed++
        if (Get-Command Write-StructuredWarning -ErrorAction SilentlyContinue) {
            Write-StructuredWarning -Message "Failed to measure full startup" -OperationName 'benchmark.startup.full' -Context @{
                iteration        = $i
                total_iterations = $Iterations
            } -Code 'BenchmarkIterationFailed'
        }
        else {
            Write-ScriptMessage -Message "Failed to measure full startup (iteration $i): $($_.Exception.Message)" -IsWarning
        }
    }
}

if ($fullStartupFailed -gt 0) {
    if ($fullStartupFailed -gt 0) {
        if (Get-Command Write-StructuredWarning -ErrorAction SilentlyContinue) {
            Write-StructuredWarning -Message "Some full startup measurements failed" -OperationName 'benchmark.startup.full' -Context @{
                failed_count     = $fullStartupFailed
                total_iterations = $Iterations
            } -Code 'BenchmarkPartialFailure'
        }
        else {
            Write-ScriptMessage -Message "Warning: $fullStartupFailed out of $Iterations full startup measurements failed" -IsWarning
        }
    }
}

$fullStartupDuration = ((Get-Date) - $fullStartupStartTime).TotalMilliseconds

# Level 2: Full startup measurement timing
if ($debugLevel -ge 2) {
    Write-Verbose "[benchmark.startup] Full startup measurement completed in ${fullStartupDuration}ms"
    Write-Verbose "[benchmark.startup] Successful iterations: $($fullResults.Count), Failed: $fullStartupFailed"
}

# 2) Measure per-fragment dot-source time: run a fresh pwsh -NoProfile that dot-sources a single fragment
# Compile regex pattern once for extracting numeric values (used in loop)
$numericRegex = [regex]::new('(\d+\.?\d*)', [System.Text.RegularExpressions.RegexOptions]::Compiled)

# Level 1: Fragment measurement start
if ($debugLevel -ge 1) {
    Write-Verbose "[benchmark.startup] Starting per-fragment load time measurement"
}

$fragments = Get-ChildItem -Path (Join-Path $WorkspaceRoot 'profile.d') -Filter '*.ps1' | Sort-Object Name
Write-ScriptMessage -Message "Measuring per-fragment load times ($($fragments.Count) fragments, $Iterations iterations each)..." -LogLevel Info
# Use List for better performance than array concatenation
$fragmentResults = [System.Collections.Generic.List[PSCustomObject]]::new()
$fragmentCount = 0
$failedFragments = [System.Collections.Generic.List[string]]::new()
$fragmentMeasurementStartTime = Get-Date
foreach ($frag in $fragments) {
    $fragmentCount++
    
    # Level 1: Individual fragment measurement
    if ($debugLevel -ge 1) {
        Write-Verbose "[benchmark.startup] Measuring fragment: $($frag.Name) ($fragmentCount/$($fragments.Count))"
    }
    Write-ScriptMessage -Message "  Fragment $fragmentCount/$($fragments.Count): $($frag.Name)..." -LogLevel Debug
    try {
        $times = [System.Collections.Generic.List[double]]::new()
        $fragmentIterationFailures = 0
        for ($i = 1; $i -le $Iterations; $i++) {
            try {
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
                Set-Content -Path $tempFrag -Value $child -Encoding UTF8 -ErrorAction Stop

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
                
                # Wait for process with timeout
                $timeoutMs = 30000  # 30 seconds per fragment
                $fragmentTimeout = $false
                if (-not $proc.WaitForExit($timeoutMs)) {
                    $fragmentTimeout = $true
                    try {
                        $proc.Kill()
                        if (Get-Command Write-StructuredWarning -ErrorAction SilentlyContinue) {
                            Write-StructuredWarning -Message "Fragment timed out" -OperationName 'benchmark.startup.fragment' -Context @{
                                fragment        = $frag.Name
                                timeout_seconds = $timeoutMs / 1000
                                iteration       = $i
                            } -Code 'FragmentTimeout'
                        }
                        else {
                            Write-Warning "Fragment $($frag.Name) timed out after $($timeoutMs/1000) seconds (iteration $i)"
                        }
                    }
                    catch {
                        # ignore errors when killing
                    }
                }
                
                $out = $proc.StandardOutput.ReadToEnd()
                [double]$val = 0
                if (-not $fragmentTimeout) {
                    $match = $numericRegex.Match($out)
                    if ($match.Success) { [double]$val = [double]$match.Groups[1].Value }
                }
                $times.Add($val)
                
                # Output timing for this iteration
                if ($val -gt 0) {
                    $formattedVal = if (Get-Command Format-LocaleNumber -ErrorAction SilentlyContinue) {
                        Format-LocaleNumber ([Math]::Round($val, 2)) -Format 'N2'
                    }
                    else {
                        [Math]::Round($val, 2).ToString("N2")
                    }
                    Write-ScriptMessage -Message "    Iteration $($i)/$($Iterations): $($formattedVal) ms" -LogLevel Debug
                }
                elseif ($fragmentTimeout) {
                    Write-ScriptMessage -Message "    Iteration $($i)/$($Iterations): TIMEOUT" -LogLevel Warning
                    $fragmentIterationFailures++
                }
                
                Remove-Item -Path $tempFrag -Force -ErrorAction SilentlyContinue
            }
            catch {
                $fragmentIterationFailures++
                if (Get-Command Write-StructuredWarning -ErrorAction SilentlyContinue) {
                    Write-StructuredWarning -Message "Failed to measure fragment" -OperationName 'benchmark.startup.fragment' -Context @{
                        fragment         = $frag.Name
                        iteration        = $i
                        total_iterations = $Iterations
                    } -Code 'BenchmarkIterationFailed'
                }
                else {
                    Write-ScriptMessage -Message "Failed to measure fragment $($frag.Name) (iteration $i): $($_.Exception.Message)" -IsWarning
                }
                # Clean up temp file if it exists
                if ($tempFrag -and (Test-Path -LiteralPath $tempFrag)) {
                    Remove-Item -Path $tempFrag -Force -ErrorAction SilentlyContinue
                }
            }
        }
        
        # Calculate statistics safely
        $meanMs = 0
        $medianMs = 0
        if ($times.Count -gt 0) {
            $meanMs = [Math]::Round(($times | Measure-Object -Average).Average, 2)
            $sorted = $times | Sort-Object
            $medianIndex = [Math]::Floor($sorted.Count / 2)
            $medianMs = [Math]::Round($sorted[$medianIndex], 2)
        }
        
        if ($fragmentIterationFailures -gt 0) {
            Write-ScriptMessage -Message "  Warning: $fragmentIterationFailures out of $Iterations iterations failed for fragment $($frag.Name)" -IsWarning
        }
        
        $fragmentResults.Add([PSCustomObject]@{
                Fragment   = $frag.Name
                Iterations = $Iterations
                MeanMs     = $meanMs
                MedianMs   = $medianMs
                Raw        = $times -join ','
            })
    }
    catch {
        $failedFragments.Add($frag.Name)
        if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
            Write-StructuredError -ErrorRecord $_ -OperationName 'benchmark.startup.fragment' -Context @{
                fragment = $frag.Name
            }
        }
        else {
            Write-ScriptMessage -Message "Failed to measure fragment $($frag.Name): $($_.Exception.Message)" -IsWarning
        }
    }
}

if ($failedFragments.Count -gt 0) {
    if ($failedFragments.Count -gt 0) {
        if (Get-Command Write-StructuredWarning -ErrorAction SilentlyContinue) {
            Write-StructuredWarning -Message "Some fragment measurements failed" -OperationName 'benchmark.startup.fragment' -Context @{
                failed_fragments = $failedFragments -join ','
                failed_count     = $failedFragments.Count
            } -Code 'BenchmarkPartialFailure'
        }
        else {
            Write-ScriptMessage -Message "Warning: Failed to measure $($failedFragments.Count) fragment(s): $($failedFragments -join ', ')" -IsWarning
        }
    }
}

$fragmentMeasurementDuration = ((Get-Date) - $fragmentMeasurementStartTime).TotalMilliseconds

# Level 2: Fragment measurement timing
if ($debugLevel -ge 2) {
    Write-Verbose "[benchmark.startup] Fragment measurement completed in ${fragmentMeasurementDuration}ms"
    Write-Verbose "[benchmark.startup] Successful fragments: $($fragmentResults.Count), Failed: $($failedFragments.Count)"
}

# Level 3: Performance breakdown
if ($debugLevel -ge 3) {
    $totalDuration = $fullStartupDuration + $fragmentMeasurementDuration
    Write-Host "  [benchmark.startup] Performance - Full startup: ${fullStartupDuration}ms, Fragments: ${fragmentMeasurementDuration}ms, Total: ${totalDuration}ms" -ForegroundColor DarkGray
}

# Print results
Write-ScriptMessage -Message "Startup benchmark (ms) - iterations: $Iterations"
$fullResultsArray = $fullResults.ToArray()
$currentMean = [Math]::Round(($fullResultsArray | Measure-Object -Average).Average, 2)
# Optimized: Use foreach loop instead of ForEach-Object
$formattedTimes = [System.Collections.Generic.List[string]]::new()
$hasFormatLocaleNumber = Get-Command Format-LocaleNumber -ErrorAction SilentlyContinue
foreach ($time in $fullResultsArray) {
    if ($hasFormatLocaleNumber) {
        $formattedTimes.Add((Format-LocaleNumber ([Math]::Round($time, 2)) -Format 'N2'))
    }
    else {
        $formattedTimes.Add([Math]::Round($time, 2).ToString("N2"))
    }
}
$currentMeanStr = if (Get-Command Format-LocaleNumber -ErrorAction SilentlyContinue) {
    Format-LocaleNumber $currentMean -Format 'N2'
}
else {
    $currentMean.ToString("N2")
}
Write-ScriptMessage -Message "Full startup times (ms): $($formattedTimes -join ', ')"
Write-ScriptMessage -Message "Full startup mean (ms): $currentMeanStr"

Write-ScriptMessage -Message "Per-fragment dot-source timings (ms):"
$fragmentResults | Sort-Object -Property MeanMs -Descending | Format-Table -AutoSize

# Performance regression detection
$baselineFile = Join-Path $WorkspaceRoot 'scripts' 'data' 'performance-baseline.json'
$regressionDetected = $false

if (Test-Path $baselineFile) {
    Write-ScriptMessage -Message "`nPerformance Regression Check:"
    try {
        $baseline = Read-JsonFile -Path $baselineFile

        # Check full startup time regression
        $baselineMean = $baseline.FullStartupMean
        $ratio = $currentMean / $baselineMean
        $ratioStr = if (Get-Command Format-LocaleNumber -ErrorAction SilentlyContinue) {
            Format-LocaleNumber ([Math]::Round($ratio, 2)) -Format 'N2'
        }
        else {
            [Math]::Round($ratio, 2).ToString("N2")
        }
        $baselineMeanStr = if (Get-Command Format-LocaleNumber -ErrorAction SilentlyContinue) {
            Format-LocaleNumber ([Math]::Round($baselineMean, 2)) -Format 'N2'
        }
        else {
            [Math]::Round($baselineMean, 2).ToString("N2")
        }
        Write-ScriptMessage -Message "Full startup: Current=$currentMeanStr ms, Baseline=$baselineMeanStr ms, Ratio=${ratioStr}x"

        if ($ratio -gt $RegressionThreshold) {
            $regressionPercentStr = if (Get-Command Format-LocaleNumber -ErrorAction SilentlyContinue) {
                Format-LocaleNumber ([Math]::Round(($ratio - 1) * 100, 1)) -Format 'N1'
            }
            else {
                [Math]::Round(($ratio - 1) * 100, 1).ToString("N1")
            }
            $thresholdPercentStr = if (Get-Command Format-LocaleNumber -ErrorAction SilentlyContinue) {
                Format-LocaleNumber ([Math]::Round(($RegressionThreshold - 1) * 100, 1)) -Format 'N1'
            }
            else {
                [Math]::Round(($RegressionThreshold - 1) * 100, 1).ToString("N1")
            }
            Write-ScriptMessage -Message "PERFORMANCE REGRESSION: Full startup time increased by ${regressionPercentStr}% (threshold: ${thresholdPercentStr}%)" -IsWarning
            $regressionDetected = $true
        }

        # Check per-fragment regressions
        # Optimized: Build lookup dictionary for O(1) fragment lookup
        $baselineFragmentLookup = @{}
        foreach ($bf in $baseline.Fragments) {
            $baselineFragmentLookup[$bf.Fragment] = $bf
        }
        foreach ($frag in $fragmentResults) {
            $baselineFrag = if ($baselineFragmentLookup.ContainsKey($frag.Fragment)) { $baselineFragmentLookup[$frag.Fragment] } else { $null }
            if ($baselineFrag) {
                $fragRatio = $frag.MeanMs / $baselineFrag.MeanMs
                if ($fragRatio -gt $RegressionThreshold) {
                    $fragRegressionPercentStr = if (Get-Command Format-LocaleNumber -ErrorAction SilentlyContinue) {
                        Format-LocaleNumber ([Math]::Round(($fragRatio - 1) * 100, 1)) -Format 'N1'
                    }
                    else {
                        [Math]::Round(($fragRatio - 1) * 100, 1).ToString("N1")
                    }
                    Write-ScriptMessage -Message "PERFORMANCE REGRESSION: $($frag.Fragment) increased by ${fragRegressionPercentStr}% (current: $($frag.MeanMs)ms, baseline: $($baselineFrag.MeanMs)ms)" -IsWarning
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
    # Optimized: Use foreach loop instead of ForEach-Object
    $fragmentData = [System.Collections.Generic.List[hashtable]]::new()
    foreach ($frag in $fragmentResults) {
        $fragmentData.Add(@{
                Fragment = $frag.Fragment
                MeanMs   = $frag.MeanMs
                MedianMs = $frag.MedianMs
                Raw      = $frag.Raw
            }
        )
    }
    $baselineData = @{
        Timestamp       = (Get-Date).ToString('o')
        FullStartupMean = $currentMean
        FullStartupRaw  = $fullResultsArray
        Fragments       = $fragmentData
    }

    Write-JsonFile -Path $baselineFile -InputObject $baselineData -Depth 10 -EnsureDirectory
    Write-ScriptMessage -Message "`nUpdated performance baseline: $baselineFile"
}

# Save CSV - ensure data directory exists
$dataDir = Join-Path $WorkspaceRoot 'scripts' 'data'
try {
    if (Get-Command Ensure-DirectoryExists -ErrorAction SilentlyContinue) {
        Ensure-DirectoryExists -Path $dataDir
    }
    else {
        # Fallback: create directory manually
        if (-not (Test-Path -LiteralPath $dataDir)) {
            New-Item -ItemType Directory -Path $dataDir -Force | Out-Null
        }
    }
}
catch {
    if (Get-Command Exit-WithCode -ErrorAction SilentlyContinue) {
        Exit-WithCode -ExitCode [ExitCode]::SetupError -ErrorRecord $_
    }
    else {
        if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
            Write-StructuredError -ErrorRecord $_ -OperationName 'benchmark.startup.save-results' -Context @{
                data_directory = $dataDir
            }
        }
        else {
            Write-Error "Failed to create data directory: $($_.Exception.Message)"
        }
        exit 2
    }
}

$csvOut = Join-Path $dataDir 'startup-benchmark.csv'
$fragmentResults | Export-Csv -Path $csvOut -NoTypeInformation -Force
Write-ScriptMessage -Message "`nSaved per-fragment results to: $csvOut"

# Also record to SQLite database if available
$performanceMetricsModule = Join-Path $WorkspaceRoot 'scripts' 'lib' 'database' 'PerformanceMetricsDatabase.psm1'
if (Test-Path -LiteralPath $performanceMetricsModule) {
    try {
        Import-Module $performanceMetricsModule -DisableNameChecking -ErrorAction SilentlyContinue
        if (Get-Command Add-PerformanceMetric -ErrorAction SilentlyContinue) {
            $environment = if ($env:CI) { 'CI' } else { 'local' }
            
            # Record full startup time
            Add-PerformanceMetric -MetricType 'startup' -MetricName 'full_startup_mean' -Value $currentMean -Unit 'ms' -Environment $environment -Metadata @{
                Source     = 'benchmark_startup'
                Iterations = $Iterations
            }
            
            # Record fragment timings
            foreach ($frag in $fragmentResults) {
                if ($frag.MeanMs) {
                    Add-PerformanceMetric -MetricType 'startup' -MetricName "fragment_$($frag.Fragment)" -Value $frag.MeanMs -Unit 'ms' -Environment $environment -Metadata @{
                        Source   = 'benchmark_startup'
                        Fragment = $frag.Fragment
                        MedianMs = $frag.MedianMs
                    }
                }
            }
            
            Write-ScriptMessage -Message "Recorded metrics to SQLite database" -LogLevel Debug
        }
    }
    catch {
        # Silently fail - database recording is optional
        # Level 2: Database recording error (using standard debug level)
        if ($debugLevel -ge 2) {
            Write-Verbose "[benchmark.startup] Failed to record to database: $($_.Exception.Message)"
        }
    }
}

# Exit with error if regression detected (unless updating baseline)
if ($regressionDetected -and -not $UpdateBaseline) {
    Pop-Location
    if (Get-Command Exit-WithCode -ErrorAction SilentlyContinue) {
        Exit-WithCode -ExitCode [ExitCode]::ValidationFailure -Message "Performance regression detected. Use -UpdateBaseline to accept new performance baseline."
    }
    else {
        if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
            $errorRecord = [System.Management.Automation.ErrorRecord]::new(
                [System.InvalidOperationException]::new("Performance regression detected"),
                'PerformanceRegression',
                [System.Management.Automation.ErrorCategory]::InvalidOperation,
                $null
            )
            Write-StructuredError -ErrorRecord $errorRecord -OperationName 'benchmark.startup.regression-check' -Context @{
                regression_threshold = $RegressionThreshold
            }
        }
        else {
            Write-Error "Performance regression detected. Use -UpdateBaseline to accept new performance baseline."
        }
        exit 1
    }
}

Pop-Location
if (Get-Command Exit-WithCode -ErrorAction SilentlyContinue) {
    Exit-WithCode -ExitCode [ExitCode]::Success -Message "Benchmark completed successfully"
}
else {
    Write-Host "Benchmark completed successfully"
    exit 0
}

