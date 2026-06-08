# ===============================================
# run-tests-with-interception.ps1
# Run tests with Test-Path interception enabled
# ===============================================

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$TestFile
)

Write-Host "🔍 Running tests with Test-Path interception..." -ForegroundColor Cyan
Write-Host "   Test File: $TestFile" -ForegroundColor Gray
Write-Host ""

$interceptScript = Join-Path $PSScriptRoot 'intercept-testpath.ps1'
$escapedIntercept = $interceptScript.Replace("'", "''")
$escapedTestFile = $TestFile.Replace("'", "''")

# Create a script block that sets up interception and runs tests
$testScript = @"
# Load interception
. '$escapedIntercept'

# Run the test
`$ErrorActionPreference = 'Stop'
Import-Module Pester -MinimumVersion 5.0 -ErrorAction Stop
`$result = Invoke-Pester -Path '$escapedTestFile' -PassThru -Quiet

Write-Host "`n=== Test Results ===" -ForegroundColor Cyan
Write-Host "Passed: `$(`$result.PassedCount)"
Write-Host "Failed: `$(`$result.FailedCount)"
Write-Host "Skipped: `$(`$result.SkippedCount)"

exit `$result.FailedCount
"@

# Run in a new PowerShell session to avoid conflicts
pwsh -NoProfile -Command $testScript
exit $LASTEXITCODE

