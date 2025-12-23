# ===============================================
# test-fragment-loading.ps1
# Simple test to verify all migrated fragments can load
# ===============================================

<#
.SYNOPSIS
    Tests that all migrated fragments can be loaded without errors.

.DESCRIPTION
    Attempts to load each migrated fragment and reports any failures.
    This is a basic smoke test to verify migrations didn't break fragment loading.

.EXAMPLE
    pwsh -NoProfile -File scripts/utils/fragment/test-fragment-loading.ps1
#>

$ErrorActionPreference = 'Stop'

# Resolve repo root
$repoRoot = $PSScriptRoot
for ($i = 1; $i -le 3; $i++) {
    $repoRoot = Split-Path -Parent $repoRoot
}

# Get all migrated fragments
$profileDDir = Join-Path $repoRoot 'profile.d'
$fragments = Get-ChildItem -Path $profileDDir -Filter '*.ps1' | 
Where-Object { 
    $_.Name -notmatch '^[0-9]+-' -and 
    $_.Name -ne 'files-module-registry.ps1' 
} | Sort-Object Name

Write-Host "Testing fragment loading for $($fragments.Count) fragments..." -ForegroundColor Cyan
Write-Host ""

$successCount = 0
$failureCount = 0
$failures = @()

# Load bootstrap first (required for most fragments)
$bootstrapPath = Join-Path $profileDDir 'bootstrap.ps1'
if (Test-Path $bootstrapPath) {
    try {
        . $bootstrapPath
        Write-Host "✅ bootstrap.ps1 loaded successfully" -ForegroundColor Green
        $successCount++
    }
    catch {
        Write-Host "❌ bootstrap.ps1 failed: $($_.Exception.Message)" -ForegroundColor Red
        $failureCount++
        $failures += "bootstrap.ps1: $($_.Exception.Message)"
    }
}

# Test loading each fragment with timing
foreach ($fragment in $fragments) {
    if ($fragment.Name -eq 'bootstrap.ps1') {
        continue  # Already tested
    }
    
    try {
        # Clear any fragment loaded state for this fragment
        $fragmentName = $fragment.BaseName
        if (Get-Command Clear-FragmentLoaded -ErrorAction SilentlyContinue) {
            Clear-FragmentLoaded -FragmentName $fragmentName -ErrorAction SilentlyContinue
        }
        
        # Measure load time
        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
        
        # Set $PSScriptRoot for fragments that expect it (like local-overrides.ps1)
        $originalPSScriptRoot = $PSScriptRoot
        $PSScriptRoot = $fragment.DirectoryName
        
        # Attempt to load the fragment
        . $fragment.FullName
        
        # Restore original $PSScriptRoot
        $PSScriptRoot = $originalPSScriptRoot
        
        $stopwatch.Stop()
        $loadTime = $stopwatch.ElapsedMilliseconds
        
        $statusColor = if ($loadTime -gt 100) { 'Yellow' } else { 'Green' }
        $timeIndicator = if ($loadTime -gt 100) { " (${loadTime}ms)" } else { "" }
        Write-Host "✅ $($fragment.Name) loaded successfully$timeIndicator" -ForegroundColor $statusColor
        $successCount++
    }
    catch {
        Write-Host "❌ $($fragment.Name) failed: $($_.Exception.Message)" -ForegroundColor Red
        $failureCount++
        $failures += "$($fragment.Name): $($_.Exception.Message)"
    }
}

Write-Host ""
Write-Host "=" * 60 -ForegroundColor Cyan
Write-Host "Test Summary" -ForegroundColor Cyan
Write-Host "=" * 60 -ForegroundColor Cyan
Write-Host "Total fragments: $($fragments.Count)" -ForegroundColor White
Write-Host "Successfully loaded: $successCount" -ForegroundColor Green
Write-Host "Failed to load: $failureCount" -ForegroundColor $(if ($failureCount -eq 0) { 'Green' } else { 'Red' })

if ($failures.Count -gt 0) {
    Write-Host ""
    Write-Host "Failures:" -ForegroundColor Red
    foreach ($failure in $failures) {
        Write-Host "  - $failure" -ForegroundColor Red
    }
    exit 1
}
else {
    Write-Host ""
    Write-Host "✅ All fragments loaded successfully!" -ForegroundColor Green
    exit 0
}

