# ===============================================
# run-tests-with-trace.ps1
# Run tests with Test-Path debug tracing enabled
# ===============================================

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$TestFile
)

# Enable verbose debug logging
$env:PS_PROFILE_DEBUG_TESTPATH = 'verbose'

Write-Host "🔍 Test-Path Debug Tracing Enabled" -ForegroundColor Cyan
Write-Host "   Test File: $TestFile" -ForegroundColor Gray
Write-Host "   Any Test-SafePath calls with null/empty paths will be logged below" -ForegroundColor Gray
Write-Host ""

$escapedTestFile = $TestFile.Replace("'", "''")

try {
    pwsh -NoProfile -Command @"
        `$ErrorActionPreference = 'Stop'
        Import-Module Pester -MinimumVersion 5.0 -ErrorAction Stop
        `$result = Invoke-Pester -Path '$escapedTestFile' -PassThru -Quiet
        Write-Host "`n=== Test Results ===" -ForegroundColor Cyan
        Write-Host "Passed: `$(`$result.PassedCount)"
        Write-Host "Failed: `$(`$result.FailedCount)"
        Write-Host "Skipped: `$(`$result.SkippedCount)"
        exit `$result.FailedCount
"@
    exit $LASTEXITCODE
}
finally {
    Remove-Item Env:\PS_PROFILE_DEBUG_TESTPATH -ErrorAction SilentlyContinue
}
