#Requires -Version 7.0
<#
.SYNOPSIS
    Runs conversion integration tests under a directory.

.DESCRIPTION
    Discovers *.tests.ps1 files recursively under the requested conversion subdirectory.
    By default runs all matching files in a single Pester session (one run-pester startup).
    Use -PerFile for per-file runs with individual pass/fail lines (slower; useful when
    isolating a failing file).

.PARAMETER RelativePath
    Path relative to tests/integration/conversion/ (default: data/compression).

.PARAMETER RepoRoot
    Repository root directory.

.PARAMETER PerFile
    Run each test file in a separate run-pester process (slow; ~60s startup per file).

.PARAMETER Quiet
    Pass -Quiet to run-pester to reduce runner output.

.PARAMETER Parallel
    Pass -Parallel to run-pester for parallel test execution within the session.

.PARAMETER NamePattern
    Optional case-insensitive regex matched against each test file basename
    (e.g. '^[a-m]' for CI shard splits). When set, runs use -PerFile isolation
    (staging under test-artifacts is unsafe because Remove-TestArtifacts wipes it).

.EXAMPLE
    pwsh -NoProfile -File scripts/utils/code-quality/run-conversion-integration-batch.ps1 -RelativePath data/structured

.EXAMPLE
    pwsh -NoProfile -File scripts/utils/code-quality/run-conversion-integration-batch.ps1 -RelativePath data/structured -PerFile
#>
param(
    [string]$RepoRoot = (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))),

    [string]$RelativePath = 'data/compression',

    [switch]$PerFile,

    [switch]$Quiet,

    [ValidateRange(0, 100)]
    [int]$Parallel = 0,

    [string]$NamePattern = ''
)

$conversionRoot = Join-Path $RepoRoot 'tests' 'integration' 'conversion'
$testDir = Join-Path $conversionRoot $RelativePath
if (-not (Test-Path -LiteralPath $testDir)) {
    Write-Error "Test directory not found: $testDir"
    exit 2
}

$runner = Join-Path $RepoRoot 'scripts' 'utils' 'code-quality' 'run-pester.ps1'
$files = @(Get-ChildItem -Path $testDir -Filter '*.tests.ps1' -File -Recurse | Sort-Object FullName)

if (-not [string]::IsNullOrWhiteSpace($NamePattern)) {
    $files = @($files | Where-Object { $_.Name -match $NamePattern })
}

if ($files.Count -eq 0) {
    $hint = if ([string]::IsNullOrWhiteSpace($NamePattern)) { '' } else { " (NamePattern: $NamePattern)" }
    Write-Error "No *.tests.ps1 files under: $testDir$hint"
    exit 2
}

function Get-PesterRunStats {
    param(
        [string]$Output,
        [string]$ResultXmlPath
    )

    $passed = -1
    $failed = -1
    $skipped = 0

    if ($Output -match 'Tests completed:\s*Passed=(\d+),\s*Failed=(\d+),\s*Skipped=(\d+)') {
        $passed = [int]$Matches[1]
        $failed = [int]$Matches[2]
        $skipped = [int]$Matches[3]
    }
    elseif ($Output -match 'Tests Passed:\s*(\d+)') {
        $passed = [int]$Matches[1]
        if ($Output -match 'Failed:\s*(\d+)') { $failed = [int]$Matches[1] }
        if ($Output -match 'Skipped:\s*(\d+)') { $skipped = [int]$Matches[1] }
    }
    elseif ($ResultXmlPath -and (Test-Path -LiteralPath $ResultXmlPath)) {
        try {
            [xml]$xml = Get-Content -LiteralPath $ResultXmlPath -ErrorAction Stop
            $root = $xml.'test-results'
            if ($root) {
                $total = [int]$root.total
                $failures = [int]$root.failures + [int]$root.errors
                $skippedCount = [int]$root.skipped + [int]$root.ignored
                if ($total -gt 0) {
                    $passed = $total - $failures - $skippedCount
                    $failed = $failures
                    $skipped = $skippedCount
                }
            }
        }
        catch {
            # Fall through to -1 stats; caller uses exit code.
        }
    }

    [pscustomobject]@{
        Passed  = $passed
        Failed  = $failed
        Skipped = $skipped
    }
}

function Get-PesterFailureLines {
    param(
        [string]$Output,
        [string]$ResultXmlPath
    )

    $lines = [System.Collections.Generic.List[string]]::new()
    [regex]::Matches($Output, '(?m)^\s+\[-\].*') | ForEach-Object { $lines.Add($_.Value.Trim()) }

    $xmlCandidates = @()
    if ($ResultXmlPath -and -not [string]::IsNullOrWhiteSpace($ResultXmlPath)) {
        if (Test-Path -LiteralPath $ResultXmlPath -PathType Leaf) {
            $xmlCandidates += $ResultXmlPath
        }
        elseif (Test-Path -LiteralPath $ResultXmlPath -PathType Container) {
            $xmlCandidates += @(Get-ChildItem -LiteralPath $ResultXmlPath -Filter '*.xml' -Recurse -File -ErrorAction SilentlyContinue |
                Select-Object -ExpandProperty FullName)
        }
    }

    foreach ($xmlPath in $xmlCandidates) {
        try {
            [xml]$xml = Get-Content -LiteralPath $xmlPath -Raw -ErrorAction Stop
            foreach ($case in @($xml.SelectNodes('//test-case[@result="Failure" or @result="Error"]'))) {
                $name = [string]$case.GetAttribute('name')
                $messageNode = $case.SelectSingleNode('.//failure/message')
                $message = if ($messageNode) { [string]$messageNode.InnerText } else { '' }
                if ([string]::IsNullOrWhiteSpace($name) -and [string]::IsNullOrWhiteSpace($message)) {
                    continue
                }
                $summary = if ($message) { "${name}: $message" } else { $name }
                if (-not [string]::IsNullOrWhiteSpace($summary) -and -not $lines.Contains($summary)) {
                    $lines.Add($summary.Trim())
                }
            }
        }
        catch {
            # Ignore unreadable result XML; output-based lines may still be available.
        }
    }

    return @($lines)
}

function Invoke-ConversionBatchRunner {
    param(
        [string[]]$RunnerArgs
    )

    # Child pwsh process keeps run-pester isolated (in-process runs fail en masse).
    $output = & pwsh @RunnerArgs 2>&1 | Out-String
    $exitCode = if ($null -ne $LASTEXITCODE) { $LASTEXITCODE } else { 0 }
    return [pscustomobject]@{
        Output   = $output
        ExitCode = $exitCode
    }
}

function New-BatchRunnerArgs {
    param(
        [Parameter(Mandatory)]
        [string]$TargetPath,
        [string]$ResultPath
    )

    $args = @(
        '-NoProfile'
        '-File'
        $runner
        '-Suite'
        'Integration'
        '-Path'
        $TargetPath
    )
    if ($Quiet) {
        $args += '-Quiet'
    }
    if ($Parallel -gt 0) {
        $args += '-MaxParallelThreads'
        $args += $Parallel
    }
    if ($ResultPath) {
        $args += '-TestResultPath'
        $args += $ResultPath
    }
    return $args
}

$label = $RelativePath -replace '[/\\]', '/'
if (-not [string]::IsNullOrWhiteSpace($NamePattern)) {
    $label = "$label (NamePattern=$NamePattern)"
    # Staging filtered files under tests/test-artifacts breaks conversion tests:
    # AfterEach Remove-TestArtifacts wipes the staged scripts mid-run, and
    # NamePattern hashes like ^markdown vs ^(?!markdown) collided on sanitized
    # artifact names. Per-file isolation avoids both issues.
    if (-not $PerFile) {
        $PerFile = $true
        Write-Host 'NamePattern set: using -PerFile (staging is unsafe for conversion tests)' -ForegroundColor DarkGray
    }
}
Write-Host "Batch: $label ($($files.Count) files)" -ForegroundColor Cyan

if (-not $PerFile) {
    Write-Host "Mode: single session (use -PerFile for per-file breakdown)" -ForegroundColor DarkGray
    Write-Host ''

    $resultDir = Join-Path $RepoRoot 'tests' 'test-artifacts' 'conversion-batch'
    $null = New-Item -ItemType Directory -Path $resultDir -Force -ErrorAction SilentlyContinue
    $resultKey = ($RelativePath -replace '[/\\]', '-')
    # run-pester -TestResultPath expects a directory (not a .xml file path).
    $resultPath = Join-Path $resultDir $resultKey
    if (Test-Path -LiteralPath $resultPath) {
        Remove-Item -LiteralPath $resultPath -Recurse -Force -Confirm:$false -ErrorAction SilentlyContinue
    }
    $null = New-Item -ItemType Directory -Path $resultPath -Force -ErrorAction SilentlyContinue
    $resultXml = Join-Path $resultPath 'test-results.xml'

    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    $run = Invoke-ConversionBatchRunner -RunnerArgs (New-BatchRunnerArgs -TargetPath $testDir -ResultPath $resultPath)
    $sw.Stop()

    $stats = Get-PesterRunStats -Output $run.Output -ResultXmlPath $resultXml
    if ($stats.Failed -lt 0) {
        # Prefer the runner's default XML name when present under the result directory.
        $stats = Get-PesterRunStats -Output $run.Output -ResultXmlPath $resultPath
    }
    $failLines = @(Get-PesterFailureLines -Output $run.Output -ResultXmlPath $resultPath)
    # Prefer parsed Pester counts when available; child exit codes can be non-zero
    # from non-terminating warnings even when FailedCount is 0.
    $batchFailed = if ($stats.Failed -ge 0) {
        $stats.Failed -gt 0
    }
    else {
        $run.ExitCode -ne 0
    }

    $color = if ($batchFailed) { 'Red' } elseif ($stats.Passed -ge 0) { 'Green' } else { 'Yellow' }
    Write-Host "  $($stats.Passed)P / $($stats.Failed)F / $($stats.Skipped)S in $([math]::Round($sw.Elapsed.TotalSeconds, 1))s" -ForegroundColor $color
    if ($failLines.Count -gt 0) {
        $failLines | Select-Object -First 5 | ForEach-Object { Write-Host "    $_" -ForegroundColor DarkRed }
    }
    elseif ($batchFailed -and $stats.Failed -lt 0 -and -not [string]::IsNullOrWhiteSpace($run.Output)) {
        # Runner crashed / misconfigured before emitting Pester counts — surface the reason.
        ($run.Output -split "`n" | Where-Object { $_ -match '\S' } | Select-Object -Last 12) |
            ForEach-Object { Write-Host "    $_" -ForegroundColor DarkRed }
    }

    Write-Host ''
    Write-Host "--- Summary ($label) ---" -ForegroundColor Cyan
    [pscustomobject]@{
        File     = "(all $($files.Count) files)"
        Passed   = $stats.Passed
        Failed   = $stats.Failed
        Skipped  = $stats.Skipped
        Failures = ($failLines -join ' | ')
    } | Format-Table -AutoSize

    if ($batchFailed) {
        Write-Host "Batch failed: $label" -ForegroundColor Red
        Write-Host "Re-run with -PerFile to see which file failed." -ForegroundColor DarkGray
        exit 1
    }

    Write-Host "All tests passed in batch: $label" -ForegroundColor Green
    exit 0
}

Write-Host "Mode: per-file (slow)" -ForegroundColor DarkGray
Write-Host ''

$results = @()
foreach ($file in $files) {
    $relName = $file.FullName.Substring($conversionRoot.Length).TrimStart('/', '\')
    Write-Host "=== $relName ===" -ForegroundColor Cyan
    $run = Invoke-ConversionBatchRunner -RunnerArgs (New-BatchRunnerArgs -TargetPath $file.FullName)
    $stats = Get-PesterRunStats -Output $run.Output
    $failLines = @(Get-PesterFailureLines -Output $run.Output)

    $results += [pscustomobject]@{
        File     = $relName
        Passed   = $stats.Passed
        Failed   = $stats.Failed
        Skipped  = $stats.Skipped
        Failures = ($failLines -join ' | ')
    }

    $color = if ($stats.Failed -gt 0) { 'Red' } elseif ($stats.Passed -ge 0) { 'Green' } else { 'Yellow' }
    Write-Host "  $($stats.Passed)P / $($stats.Failed)F / $($stats.Skipped)S" -ForegroundColor $color
    if ($failLines.Count -gt 0) {
        $failLines | Select-Object -First 3 | ForEach-Object { Write-Host "    $_" -ForegroundColor DarkRed }
    }
}

Write-Host ''
Write-Host "--- Summary ($label) ---" -ForegroundColor Cyan
$results | Format-Table -AutoSize
$bad = @($results | Where-Object { $_.Failed -gt 0 })
if ($bad.Count -gt 0) {
    Write-Host "Files with failures: $($bad.Count)" -ForegroundColor Red
    exit 1
}

Write-Host "All tests passed in batch: $label" -ForegroundColor Green
exit 0
