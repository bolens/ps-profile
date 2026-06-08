#Requires -Version 7.0
<#
.SYNOPSIS
    Runs all conversion integration test sub-batches.

.DESCRIPTION
    Invokes run-conversion-integration-batch.ps1 for each subdirectory under
    tests/integration/conversion/. Avoids top-level data/document/media single
    sessions (SIGSEGV on some hosts); uses per-subdir batches instead.

.PARAMETER RepoRoot
    Repository root directory.

.PARAMETER RelativePath
    Optional sub-batch path(s) relative to tests/integration/conversion/.
    When omitted, all discovered sub-batches are run.

.PARAMETER Quiet
    Pass -Quiet to each sub-batch runner.

.PARAMETER PerFile
    Pass -PerFile to each sub-batch runner (very slow).

.PARAMETER Parallel
    Pass -Parallel to each sub-batch runner.

.EXAMPLE
    pwsh -NoProfile -File scripts/utils/code-quality/run-conversion-all-batch.ps1 -Quiet

.EXAMPLE
    pwsh -NoProfile -File scripts/utils/code-quality/run-conversion-all-batch.ps1 -RelativePath data/encoding -Quiet
#>
param(
    [string]$RepoRoot = (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))),

    [string[]]$RelativePath = @(),

    [switch]$Quiet,

    [switch]$PerFile,

    [ValidateRange(0, 100)]
    [int]$Parallel = 0
)

$conversionRoot = Join-Path $RepoRoot 'tests' 'integration' 'conversion'
$batchRunner = Join-Path $RepoRoot 'scripts' 'utils' 'code-quality' 'run-conversion-integration-batch.ps1'

if (-not (Test-Path -LiteralPath $batchRunner)) {
    Write-Error "Batch runner not found: $batchRunner"
    exit 2
}

function Get-ConversionBatchPaths {
    param([string]$Root)

    $paths = [System.Collections.Generic.List[string]]::new()

    foreach ($top in Get-ChildItem -Path $Root -Directory | Sort-Object Name) {
        $directTests = @(Get-ChildItem -Path $top.FullName -Filter '*.tests.ps1' -File -ErrorAction SilentlyContinue)
        if ($directTests.Count -gt 0) {
            $paths.Add($top.Name)
        }

        if ($top.Name -in @('data', 'media')) {
            foreach ($sub in Get-ChildItem -Path $top.FullName -Directory | Sort-Object Name) {
                $subTests = @(Get-ChildItem -Path $sub.FullName -Filter '*.tests.ps1' -File -Recurse -ErrorAction SilentlyContinue)
                if ($subTests.Count -gt 0) {
                    $paths.Add(('{0}/{1}' -f $top.Name, $sub.Name))
                }
            }
        }
    }

    return @($paths)
}

$paths = if ($RelativePath.Count -gt 0) {
    @($RelativePath)
}
else {
    Get-ConversionBatchPaths -Root $conversionRoot
}

if ($paths.Count -eq 0) {
    Write-Error 'No conversion batch paths discovered.'
    exit 2
}

Write-Host "Conversion all-batch: $($paths.Count) sub-batches" -ForegroundColor Cyan
Write-Host ''

$results = @()
foreach ($rel in $paths) {
    Write-Host "=== $rel ===" -ForegroundColor Cyan

    $runnerArgs = @(
        '-NoProfile'
        '-NonInteractive'
        '-File'
        $batchRunner
        '-RelativePath'
        $rel
    )
    if ($Quiet) { $runnerArgs += '-Quiet' }
    if ($PerFile) { $runnerArgs += '-PerFile' }
    if ($Parallel -gt 0) {
        $runnerArgs += '-Parallel'
        $runnerArgs += $Parallel
    }

    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    $output = & pwsh @runnerArgs 2>&1 | Out-String
    $sw.Stop()
    $exitCode = if ($null -ne $LASTEXITCODE) { $LASTEXITCODE } else { 0 }

    $passed = -1
    $failed = -1
    $skipped = 0
    if ($output -match '(\d+)P\s*/\s*(\d+)F\s*/\s*(\d+)S') {
        $passed = [int]$Matches[1]
        $failed = [int]$Matches[2]
        $skipped = [int]$Matches[3]
    }

    $batchFailed = $exitCode -ne 0 -or $failed -gt 0
    $results += [pscustomobject]@{
        Path     = $rel
        Passed   = $passed
        Failed   = $failed
        Skipped  = $skipped
        Seconds  = [math]::Round($sw.Elapsed.TotalSeconds, 1)
        ExitCode = $exitCode
    }

    $color = if ($batchFailed) { 'Red' } elseif ($passed -ge 0) { 'Green' } else { 'Yellow' }
    Write-Host "  $($results[-1].Passed)P / $($results[-1].Failed)F / $($results[-1].Skipped)S in $($results[-1].Seconds)s" -ForegroundColor $color
    Write-Host ''
}

Write-Host '--- Summary (conversion all) ---' -ForegroundColor Cyan
$results | Format-Table -AutoSize

$bad = @($results | Where-Object { $_.Failed -gt 0 -or $_.ExitCode -ne 0 })
if ($bad.Count -gt 0) {
    Write-Host "Sub-batches with failures: $($bad.Count)" -ForegroundColor Red
    exit 1
}

Write-Host 'All conversion sub-batches passed.' -ForegroundColor Green
exit 0
