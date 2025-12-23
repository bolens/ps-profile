# ===============================================
# validate-fragment-dependencies.ps1
# Validates fragment dependencies and load order
# ===============================================

<#
.SYNOPSIS
    Validates all fragment dependencies and checks for missing or circular dependencies.

.DESCRIPTION
    Checks that all fragments have correct dependencies declared and that there are no
    missing or circular dependencies.

.EXAMPLE
    pwsh -NoProfile -File scripts/utils/fragment/validate-fragment-dependencies.ps1
#>

$ErrorActionPreference = 'Stop'

# Resolve repo root
$repoRoot = $PSScriptRoot
for ($i = 1; $i -le 3; $i++) {
    $repoRoot = Split-Path -Parent $repoRoot
}

# Import required modules
$fragmentLoadingPath = Join-Path $repoRoot 'scripts' 'lib' 'fragment' 'FragmentLoading.psm1'
if (-not (Test-Path $fragmentLoadingPath)) {
    Write-Error "FragmentLoading module not found at: $fragmentLoadingPath"
    exit 1
}
Import-Module $fragmentLoadingPath -DisableNameChecking -ErrorAction Stop

# Get all fragments (exclude numbered fragments and module registry)
$profileDDir = Join-Path $repoRoot 'profile.d'
$fragments = Get-ChildItem -Path $profileDDir -Filter '*.ps1' | 
Where-Object { 
    $_.Name -notmatch '^[0-9]+-' -and 
    $_.Name -ne 'files-module-registry.ps1' 
}

Write-Host "Validating dependencies for $($fragments.Count) fragments..." -ForegroundColor Cyan
Write-Host ""

# Validate dependencies
$result = Test-FragmentDependencies -FragmentFiles $fragments

if ($result.Valid) {
    Write-Host "✅ All dependencies are valid!" -ForegroundColor Green
    Write-Host ""
    
    # Show load order
    $sorted = Get-FragmentLoadOrder -FragmentFiles $fragments
    Write-Host "Fragment load order (first 20):" -ForegroundColor Cyan
    $sorted | Select-Object -First 20 | ForEach-Object {
        $deps = Get-FragmentDependencies -FragmentFile $_
        $tier = Get-FragmentTier -FragmentFile $_
        Write-Host "  $($_.Name.PadRight(30)) [Tier: $tier] (deps: $($deps -join ', '))" -ForegroundColor Gray
    }
    if ($sorted.Count -gt 20) {
        Write-Host "  ... and $($sorted.Count - 20) more" -ForegroundColor Gray
    }
    
    exit 0
}
else {
    Write-Host "❌ Dependency validation failed!" -ForegroundColor Red
    Write-Host ""
    
    if ($result.MissingDependencies.Count -gt 0) {
        Write-Host "Missing dependencies:" -ForegroundColor Yellow
        $result.MissingDependencies | ForEach-Object {
            Write-Host "  - $_" -ForegroundColor Red
        }
        Write-Host ""
    }
    
    if ($result.CircularDependencies.Count -gt 0) {
        Write-Host "Circular dependencies:" -ForegroundColor Yellow
        $result.CircularDependencies | ForEach-Object {
            Write-Host "  - $_" -ForegroundColor Red
        }
        Write-Host ""
    }
    
    exit 1
}

