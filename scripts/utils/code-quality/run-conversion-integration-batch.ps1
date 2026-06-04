#Requires -Version 7.0
<#
.SYNOPSIS
    Runs conversion integration tests under a directory, one file at a time.

.DESCRIPTION
    Per-file Pester runs with pass/fail/skip summary. Use -RelativePath to target
    a subtree under tests/integration/conversion/ (e.g. data/compression, document).

.PARAMETER RelativePath
    Path relative to tests/integration/conversion/ (default: data/compression).

.PARAMETER RepoRoot
    Repository root directory.

.EXAMPLE
    pwsh -NoProfile -File scripts/utils/code-quality/run-conversion-integration-batch.ps1 -RelativePath document
#>
param(
    [string]$RepoRoot = (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))),

    [string]$RelativePath = 'data/compression'
)

$conversionRoot = Join-Path $RepoRoot 'tests' 'integration' 'conversion'
$testDir = Join-Path $conversionRoot $RelativePath
if (-not (Test-Path -LiteralPath $testDir)) {
    Write-Error "Test directory not found: $testDir"
    exit 2
}

$runner = Join-Path $RepoRoot 'scripts' 'utils' 'code-quality' 'run-pester.ps1'
$files = Get-ChildItem -Path $testDir -Filter '*.tests.ps1' -File -Recurse | Sort-Object FullName

if ($files.Count -eq 0) {
    Write-Error "No *.tests.ps1 files under: $testDir"
    exit 2
}

$label = $RelativePath -replace '[/\\]', '/'
Write-Host "Batch: $label ($($files.Count) files)" -ForegroundColor Cyan
Write-Host ''

$results = @()
foreach ($file in $files) {
    $relName = $file.FullName.Substring($conversionRoot.Length).TrimStart('/', '\')
    Write-Host "=== $relName ===" -ForegroundColor Cyan
    $output = & pwsh -NoProfile -File $runner -Suite Integration -Path $file.FullName 2>&1 | Out-String
    $passed = if ($output -match 'Tests Passed:\s*(\d+)') { [int]$Matches[1] } else { -1 }
    $failed = if ($output -match 'Failed:\s*(\d+)') { [int]$Matches[1] } else { -1 }
    $skipped = if ($output -match 'Skipped:\s*(\d+)') { [int]$Matches[1] } else { 0 }
    $failLines = [regex]::Matches($output, '(?m)^\s+\[-\].*') | ForEach-Object { $_.Value.Trim() }

    $results += [pscustomobject]@{
        File     = $relName
        Passed   = $passed
        Failed   = $failed
        Skipped  = $skipped
        Failures = ($failLines -join ' | ')
    }

    $color = if ($failed -gt 0) { 'Red' } elseif ($passed -ge 0) { 'Green' } else { 'Yellow' }
    Write-Host "  ${passed}P / ${failed}F / ${skipped}S" -ForegroundColor $color
    if ($failLines.Count -gt 0) {
        $failLines | Select-Object -First 3 | ForEach-Object { Write-Host "    $_" -ForegroundColor DarkRed }
    }
}

Write-Host ''
Write-Host "--- Summary ($label) ---" -ForegroundColor Cyan
$results | Format-Table -AutoSize
$bad = $results | Where-Object { $_.Failed -gt 0 -or $_.Passed -lt 0 }
if ($bad.Count -gt 0) {
    Write-Host "Files with failures: $($bad.Count)" -ForegroundColor Red
    exit 1
}

Write-Host "All tests passed in batch: $label" -ForegroundColor Green
exit 0
