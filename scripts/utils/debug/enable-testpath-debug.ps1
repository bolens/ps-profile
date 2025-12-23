# ===============================================
# enable-testpath-debug.ps1
# Enable debug logging for Test-Path calls
# ===============================================

<#
.SYNOPSIS
    Enables debug logging for Test-Path calls that receive null/empty paths.

.DESCRIPTION
    Sets the PS_PROFILE_DEBUG_TESTPATH environment variable to enable logging
    in the Test-SafePath function. Run this before executing tests to see which
    Test-Path calls are receiving null/empty paths.

.EXAMPLE
    .\enable-testpath-debug.ps1
    pwsh -NoProfile -File scripts/utils/code-quality/run-pester.ps1 -TestFile 'tests/unit/test-support.tests.ps1'
#>

$env:PS_PROFILE_DEBUG_TESTPATH = 'verbose'
Write-Host "✅ Test-Path debug logging enabled" -ForegroundColor Green
Write-Host "   Set to: verbose (detailed call stacks)" -ForegroundColor Gray
Write-Host "   Run your tests now - any Test-SafePath calls with null/empty paths will be logged" -ForegroundColor Gray
Write-Host ""

