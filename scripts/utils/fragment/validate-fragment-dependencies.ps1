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

# Parse debug level once at script start
$debugLevel = 0
if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel)) {
    # Debug is enabled, $debugLevel contains the numeric level (1-3)
}

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

# Level 1: Basic operation start
if ($debugLevel -ge 1) {
    Write-Verbose "[fragment.validate-dependencies] Starting dependency validation"
    Write-Verbose "[fragment.validate-dependencies] Fragment count: $($fragments.Count)"
}

Write-Host "Validating dependencies for $($fragments.Count) fragments..." -ForegroundColor Cyan
Write-Host ""

# Validate dependencies
$validationStartTime = Get-Date
try {
    $result = Test-FragmentDependencies -FragmentFiles $fragments -ErrorAction Stop
    $validationDuration = ((Get-Date) - $validationStartTime).TotalMilliseconds
    
    # Level 2: Validation timing
    if ($debugLevel -ge 2) {
        Write-Verbose "[fragment.validate-dependencies] Validation completed in ${validationDuration}ms"
        Write-Verbose "[fragment.validate-dependencies] Valid: $($result.Valid)"
    }
}
catch {
    if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
        Write-StructuredError -ErrorRecord $_ -OperationName 'fragment.validate-dependencies' -Context @{
            fragment_count = $fragments.Count
        }
    }
    else {
        Write-Error "Failed to validate fragment dependencies: $($_.Exception.Message)"
    }
    exit 1
}

if ($result.Valid) {
    Write-Host "✅ All dependencies are valid!" -ForegroundColor Green
    Write-Host ""
    
    # Level 1: Load order generation
    if ($debugLevel -ge 1) {
        Write-Verbose "[fragment.validate-dependencies] Generating fragment load order"
    }
    
    # Show load order
    $loadOrderStartTime = Get-Date
    $sorted = Get-FragmentLoadOrder -FragmentFiles $fragments
    $loadOrderDuration = ((Get-Date) - $loadOrderStartTime).TotalMilliseconds
    
    # Level 2: Load order timing
    if ($debugLevel -ge 2) {
        Write-Verbose "[fragment.validate-dependencies] Load order generated in ${loadOrderDuration}ms"
        Write-Verbose "[fragment.validate-dependencies] Total fragments in order: $($sorted.Count)"
    }
    
    # Level 3: Performance breakdown
    if ($debugLevel -ge 3) {
        Write-Host "  [fragment.validate-dependencies] Performance - Validation: ${validationDuration}ms, Load order: ${loadOrderDuration}ms, Total: $($validationDuration + $loadOrderDuration)ms" -ForegroundColor DarkGray
    }
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

