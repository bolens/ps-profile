# Enable interception trace mode
$env:PS_PROFILE_DEBUG_TESTPATH_TRACE = '1'

Write-Host "🔍 Testing with early Test-Path interception..." -ForegroundColor Cyan
Write-Host ""

# Run the test
$ErrorActionPreference = 'Stop'
Import-Module Pester -MinimumVersion 5.0 -ErrorAction Stop

$result = Invoke-Pester -Path 'tests/unit/test-support.tests.ps1' -PassThru -Quiet

Write-Host ""
Write-Host "=== Test Results ===" -ForegroundColor Cyan
Write-Host "Passed: $($result.PassedCount)"
Write-Host "Failed: $($result.FailedCount)"
Write-Host "Skipped: $($result.SkippedCount)"

exit $result.FailedCount

