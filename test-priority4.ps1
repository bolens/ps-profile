$env:PS_PROFILE_TEST_MODE = '1'
$env:PS_PROFILE_TEST_RUNNER_ACTIVE = '1'
. tests\TestSupport.ps1
$result = Invoke-Pester -Path tests\integration\conversion\document -PassThru
Write-Host "Tests Passed: $($result.PassedCount), Failed: $($result.FailedCount), Skipped: $($result.SkippedCount)"
Write-Host "Total: $($result.TotalCount)"

