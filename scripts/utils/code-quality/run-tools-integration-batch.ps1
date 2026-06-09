#Requires -Version 7.0
<#
.SYNOPSIS
    Runs tools integration tests.

.DESCRIPTION
    Tools tests share global functions/aliases across files, so the default is per-file
    isolation (one run-pester process per *.tests.ps1, discovered recursively). Use
    -SingleSession for one combined run (faster but requires pwsh -NonInteractive).

.PARAMETER RelativePath
    Optional subdirectory under tests/integration/tools (default: run all tools tests).

.PARAMETER RepoRoot
    Repository root directory.

.PARAMETER SingleSession
    Run all matching files in one Pester session (use with pwsh -NonInteractive).

.PARAMETER Quiet
    Pass -Quiet to run-pester.

.EXAMPLE
    pwsh -NonInteractive -NoProfile -File scripts/utils/code-quality/run-tools-integration-batch.ps1

.EXAMPLE
    pwsh -NoProfile -File scripts/utils/code-quality/run-tools-integration-batch.ps1 -RelativePath network
#>
param(
    [string]$RepoRoot = (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))),

    [string]$RelativePath = '',

    [switch]$SingleSession,

    [switch]$Quiet
)

$toolsRoot = Join-Path $RepoRoot 'tests' 'integration' 'tools'
$testDir = if ([string]::IsNullOrWhiteSpace($RelativePath)) {
    $toolsRoot
}
else {
    Join-Path $toolsRoot $RelativePath
}

if (-not (Test-Path -LiteralPath $testDir)) {
    Write-Error "Test directory not found: $testDir"
    exit 2
}

$runner = Join-Path $RepoRoot 'scripts' 'utils' 'code-quality' 'run-pester.ps1'
$files = @(Get-ChildItem -Path $testDir -Filter '*.tests.ps1' -File -Recurse | Sort-Object FullName)

if ($files.Count -eq 0) {
    Write-Error "No *.tests.ps1 files under: $testDir"
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
    elseif ($ResultXmlPath -and (Test-Path -LiteralPath $ResultXmlPath)) {
        try {
            [xml]$xml = Get-Content -LiteralPath $ResultXmlPath -ErrorAction Stop
            $root = $xml.'test-results'
            if ($root) {
                $total = [int]$root.total
                $failures = [int]$root.failures + [int]$root.errors
                $skippedCount = [int]$root.skipped + [int]$root.ignored
                $passed = $total - $failures - $skippedCount
                $failed = $failures
                $skipped = $skippedCount
            }
        }
        catch {
            # Fall through; caller uses exit code.
        }
    }

    [pscustomobject]@{
        Passed  = $passed
        Failed  = $failed
        Skipped = $skipped
    }
}

function Invoke-ToolsBatchRunner {
    param([string[]]$RunnerArgs)

    $output = & pwsh -NonInteractive @RunnerArgs 2>&1 | Out-String
    $exitCode = if ($null -ne $LASTEXITCODE) { $LASTEXITCODE } else { 0 }
    return [pscustomobject]@{
        Output   = $output
        ExitCode = $exitCode
    }
}

function New-BatchRunnerArgs {
    param(
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
    if ($ResultPath) {
        $args += '-TestResultPath'
        $args += $ResultPath
    }
    return $args
}

$label = if ([string]::IsNullOrWhiteSpace($RelativePath)) { 'tools' } else { "tools/$RelativePath" }
Write-Host "Batch: $label ($($files.Count) files)" -ForegroundColor Cyan

if ($SingleSession) {
    Write-Host 'Mode: single session (requires pwsh -NonInteractive)' -ForegroundColor DarkGray
    Write-Host ''

    $resultDir = Join-Path $RepoRoot 'tests' 'test-artifacts' 'tools-batch'
    $null = New-Item -ItemType Directory -Path $resultDir -Force -ErrorAction SilentlyContinue

    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    $run = Invoke-ToolsBatchRunner -RunnerArgs (New-BatchRunnerArgs -TargetPath $testDir -ResultPath $resultDir)
    $sw.Stop()

    $stats = Get-PesterRunStats -Output $run.Output -ResultXmlPath (Join-Path $resultDir 'test-results.xml')
    $batchFailed = $run.ExitCode -ne 0 -or ($stats.Failed -gt 0)

    $color = if ($batchFailed) { 'Red' } elseif ($stats.Passed -ge 0) { 'Green' } else { 'Yellow' }
    Write-Host "  $($stats.Passed)P / $($stats.Failed)F / $($stats.Skipped)S in $([math]::Round($sw.Elapsed.TotalSeconds, 1))s" -ForegroundColor $color

    if ($batchFailed) {
        Write-Host "Batch failed: $label" -ForegroundColor Red
        exit 1
    }

    Write-Host "All tests passed in batch: $label" -ForegroundColor Green
    exit 0
}

Write-Host 'Mode: per-file (default for tools isolation)' -ForegroundColor DarkGray
Write-Host ''

$results = @()
foreach ($file in $files) {
    $relName = $file.FullName.Substring($toolsRoot.Length).TrimStart('/', '\')
    Write-Host "=== $relName ===" -ForegroundColor Cyan
    $run = Invoke-ToolsBatchRunner -RunnerArgs (New-BatchRunnerArgs -TargetPath $file.FullName)
    $stats = Get-PesterRunStats -Output $run.Output

    $results += [pscustomobject]@{
        File     = $relName
        Passed   = $stats.Passed
        Failed   = $stats.Failed
        Skipped  = $stats.Skipped
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
