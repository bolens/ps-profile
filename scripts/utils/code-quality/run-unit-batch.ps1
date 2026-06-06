#Requires -Version 7.0
<#
.SYNOPSIS
    Runs unit tests per file with a summary table.

.DESCRIPTION
    The full unit suite is large and can crash in a single session on some hosts.
    Default mode runs one run-pester process per *.tests.ps1 under tests/unit.

.PARAMETER Filter
    Optional glob-style name filter (e.g. profile-, library-).

.PARAMETER RepoRoot
    Repository root directory.

.PARAMETER Quiet
    Pass -Quiet to run-pester.

.EXAMPLE
    pwsh -NonInteractive -NoProfile -File scripts/utils/code-quality/run-unit-batch.ps1

.EXAMPLE
    pwsh -NonInteractive -NoProfile -File scripts/utils/code-quality/run-unit-batch.ps1 -Filter profile-
#>
param(
    [string]$RepoRoot = (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))),

    [string]$Filter = '',

    [switch]$Quiet
)

$unitRoot = Join-Path $RepoRoot 'tests' 'unit'
if (-not (Test-Path -LiteralPath $unitRoot)) {
    Write-Error "Unit test directory not found: $unitRoot"
    exit 2
}

$runner = Join-Path $RepoRoot 'scripts' 'utils' 'code-quality' 'run-pester.ps1'
$files = @(Get-ChildItem -Path $unitRoot -Filter '*.tests.ps1' -File | Sort-Object Name)
if (-not [string]::IsNullOrWhiteSpace($Filter)) {
    $files = @($files | Where-Object { $_.Name -like "*$Filter*" })
}

if ($files.Count -eq 0) {
    Write-Error "No unit test files matched under: $unitRoot (filter: '$Filter')"
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

function New-UnitRunnerArgs {
    param([string]$TargetPath)

    $args = @(
        '-NoProfile'
        '-File'
        $runner
        '-Suite'
        'Unit'
        '-Path'
        $TargetPath
    )
    if ($Quiet) {
        $args += '-Quiet'
    }
    return $args
}

$label = if ([string]::IsNullOrWhiteSpace($Filter)) { 'unit' } else { "unit ($Filter*)" }
Write-Host "Batch: $label ($($files.Count) files)" -ForegroundColor Cyan
Write-Host 'Mode: per-file' -ForegroundColor DarkGray
Write-Host ''

$results = @()
foreach ($file in $files) {
    Write-Host "=== $($file.Name) ===" -ForegroundColor Cyan
    $output = & pwsh -NonInteractive @((New-UnitRunnerArgs -TargetPath $file.FullName)) 2>&1 | Out-String
    $exitCode = if ($null -ne $LASTEXITCODE) { $LASTEXITCODE } else { 0 }
    $stats = Get-PesterRunStats -Output $output

    if ($stats.Passed -lt 0 -and $exitCode -ne 0) {
        $stats = [pscustomobject]@{ Passed = 0; Failed = 1; Skipped = 0 }
    }

    $results += [pscustomobject]@{
        File    = $file.Name
        Passed  = $stats.Passed
        Failed  = $stats.Failed
        Skipped = $stats.Skipped
    }

    $color = if ($stats.Failed -gt 0) { 'Red' } elseif ($stats.Passed -ge 0) { 'Green' } else { 'Yellow' }
    Write-Host "  $($stats.Passed)P / $($stats.Failed)F / $($stats.Skipped)S" -ForegroundColor $color
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
