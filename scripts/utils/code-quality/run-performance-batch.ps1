#Requires -Version 7.0
<#
.SYNOPSIS
    Runs performance tests per file with a summary table.

.DESCRIPTION
    The full performance suite is flaky in a single session on some hosts.
    Default mode runs one run-pester process per *.tests.ps1 under tests/performance.

.PARAMETER Filter
    Optional glob-style name filter (e.g. lang-go-).

.PARAMETER RepoRoot
    Repository root directory.

.PARAMETER Quiet
    Pass -Quiet to run-pester.

.EXAMPLE
    pwsh -NonInteractive -NoProfile -File scripts/utils/code-quality/run-performance-batch.ps1

.EXAMPLE
    pwsh -NonInteractive -NoProfile -File scripts/utils/code-quality/run-performance-batch.ps1 -Filter lang-
#>
param(
    [string]$RepoRoot = (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))),

    [string]$Filter = '',

    [switch]$Quiet
)

$perfRoot = Join-Path $RepoRoot 'tests' 'performance'
if (-not (Test-Path -LiteralPath $perfRoot)) {
    Write-Error "Performance test directory not found: $perfRoot"
    exit 2
}

$runner = Join-Path $RepoRoot 'scripts' 'utils' 'code-quality' 'run-pester.ps1'
$files = @(Get-ChildItem -Path $perfRoot -Filter '*.tests.ps1' -File | Sort-Object Name)
if (-not [string]::IsNullOrWhiteSpace($Filter)) {
    $files = @($files | Where-Object { $_.Name -like "*$Filter*" })
}

if ($files.Count -eq 0) {
    Write-Error "No performance test files matched under: $perfRoot (filter: '$Filter')"
    exit 2
}

function Get-PesterRunStats {
    param([string]$Output)

    $passed = -1
    $failed = -1
    $skipped = 0

    if ($Output -match 'Tests Passed:\s*(\d+)') {
        $passed = [int]$Matches[1]
        if ($Output -match 'Failed:\s*(\d+)') { $failed = [int]$Matches[1] }
        if ($Output -match 'Skipped:\s*(\d+)') { $skipped = [int]$Matches[1] }
    }
    elseif ($Output -match 'Tests completed:\s*Passed=(\d+),\s*Failed=(\d+),\s*Skipped=(\d+)') {
        $passed = [int]$Matches[1]
        $failed = [int]$Matches[2]
        $skipped = [int]$Matches[3]
    }

    return [pscustomobject]@{
        Passed  = $passed
        Failed  = $failed
        Skipped = $skipped
    }
}

function New-PerformanceRunnerArgs {
    param([string]$TargetPath)

    $args = @(
        '-NoProfile'
        '-File'
        $runner
        '-Suite'
        'Performance'
        '-Path'
        $TargetPath
    )
    if ($Quiet) {
        $args += '-Quiet'
    }
    return $args
}

$label = if ([string]::IsNullOrWhiteSpace($Filter)) { 'performance' } else { "performance ($Filter*)" }
Write-Host "Batch: $label ($($files.Count) files)" -ForegroundColor Cyan
Write-Host 'Mode: per-file' -ForegroundColor DarkGray
Write-Host ''

$results = @()
foreach ($file in $files) {
    Write-Host "=== $($file.Name) ===" -ForegroundColor Cyan
    $output = & pwsh -NoProfile -NonInteractive @((New-PerformanceRunnerArgs -TargetPath $file.FullName)) 2>&1 | Out-String
    $exitCode = if ($null -ne $LASTEXITCODE) { $LASTEXITCODE } else { 0 }
    $stats = Get-PesterRunStats -Output $output

    if ($stats.Passed -lt 0 -and $exitCode -ne 0) {
        $stats = [pscustomobject]@{ Passed = 0; Failed = 1; Skipped = 0; Crash = $true }
    }
    else {
        $stats | Add-Member -NotePropertyName Crash -NotePropertyValue $false -Force
    }

    $results += [pscustomobject]@{
        File    = $file.Name
        Passed  = $stats.Passed
        Failed  = $stats.Failed
        Skipped = $stats.Skipped
        Crash   = $stats.Crash
    }

    $suffix = if ($stats.Crash) { ' (crash/unparsed)' } else { '' }
    $color = if ($stats.Failed -gt 0 -or $stats.Crash) { 'Red' } elseif ($stats.Passed -ge 0) { 'Green' } else { 'Yellow' }
    Write-Host "  $($stats.Passed)P / $($stats.Failed)F / $($stats.Skipped)S$suffix" -ForegroundColor $color
}

Write-Host ''
Write-Host "--- Summary ($label) ---" -ForegroundColor Cyan
$results | Select-Object File, Passed, Failed, Skipped, Crash | Format-Table -AutoSize
$bad = @($results | Where-Object { $_.Failed -gt 0 -or $_.Crash })
$skippedOnly = @($results | Where-Object { $_.Failed -eq 0 -and $_.Passed -eq 0 -and $_.Skipped -gt 0 })
if ($bad.Count -gt 0) {
    Write-Host "Files with failures: $($bad.Count)" -ForegroundColor Red
    if ($skippedOnly.Count -gt 0) {
        Write-Host "Files skipped only: $($skippedOnly.Count)" -ForegroundColor DarkGray
    }
    exit 1
}

Write-Host "All tests passed in batch: $label" -ForegroundColor Green
exit 0
