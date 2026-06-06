#Requires -Version 7.0
<#
.SYNOPSIS
    Runs structured conversion integration tests one file at a time and reports failures.
#>
param(
    [string]$RepoRoot = (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)))
)

$testDir = Join-Path $RepoRoot 'tests' 'integration' 'conversion' 'data' 'structured'
$runner = Join-Path $RepoRoot 'scripts' 'utils' 'code-quality' 'run-pester.ps1'
$files = Get-ChildItem -Path $testDir -Filter '*.tests.ps1' -File | Sort-Object Name

$results = @()
foreach ($file in $files) {
    $name = $file.Name
    Write-Host "=== $name ===" -ForegroundColor Cyan
    $output = & pwsh -NoProfile -File $runner -Suite Integration -Path $file.FullName 2>&1 | Out-String
    $passed = -1
    $failed = -1
    $skipped = 0
    if ($output -match 'Tests Passed:\s*(\d+)') {
        $passed = [int]$Matches[1]
        if ($output -match 'Failed:\s*(\d+)') { $failed = [int]$Matches[1] }
        if ($output -match 'Skipped:\s*(\d+)') { $skipped = [int]$Matches[1] }
    }
    elseif ($output -match 'Tests completed:\s*Passed=(\d+),\s*Failed=(\d+),\s*Skipped=(\d+)') {
        $passed = [int]$Matches[1]
        $failed = [int]$Matches[2]
        $skipped = [int]$Matches[3]
    }
    $failLines = [regex]::Matches($output, '(?m)^\s+\[-\].*') | ForEach-Object { $_.Value.Trim() }

    $results += [pscustomobject]@{
        File    = $name
        Passed  = $passed
        Failed  = $failed
        Skipped = $skipped
        Failures = ($failLines -join ' | ')
    }

    $color = if ($failed -gt 0) { 'Red' } elseif ($passed -ge 0) { 'Green' } else { 'Yellow' }
    Write-Host "  ${passed}P / ${failed}F / ${skipped}S" -ForegroundColor $color
    if ($failLines.Count -gt 0) {
        $failLines | Select-Object -First 3 | ForEach-Object { Write-Host "    $_" -ForegroundColor DarkRed }
    }
}

Write-Host ''
Write-Host '--- Summary ---' -ForegroundColor Cyan
$results | Format-Table -AutoSize
$bad = $results | Where-Object { $_.Failed -gt 0 -or $_.Passed -lt 0 }
if ($bad.Count -gt 0) {
    Write-Host "Files with failures: $($bad.Count)" -ForegroundColor Red
    exit 1
}
Write-Host 'All structured tests passed.' -ForegroundColor Green
exit 0
