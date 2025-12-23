# Load interception first
. "$PSScriptRoot\intercept-testpath.ps1"

# Run the test
$ErrorActionPreference = 'Stop'
Import-Module Pester -MinimumVersion 5.0 -ErrorAction Stop

Write-Host "Running tests with interception..." -ForegroundColor Cyan
$result = Invoke-Pester -Path 'tests/unit/test-support.tests.ps1' -PassThru

Write-Host ""
Write-Host "=== Test Results ===" -ForegroundColor Cyan
Write-Host "Total: $($result.TotalCount)"
Write-Host "Passed: $($result.PassedCount)"
Write-Host "Failed: $($result.FailedCount)"
Write-Host "Skipped: $($result.SkippedCount)"

exit $result.FailedCount

