# ===============================================
# Profile Loading Diagnostic Script
# ===============================================
# This script helps diagnose why the profile isn't loading

Write-Host "=== Profile Loading Diagnostics ===" -ForegroundColor Cyan
Write-Host ""

# Check PowerShell version
Write-Host "PowerShell Version: $($PSVersionTable.PSVersion)" -ForegroundColor Yellow
Write-Host "PowerShell Edition: $($PSVersionTable.PSEdition)" -ForegroundColor Yellow
Write-Host ""

# Check profile paths
Write-Host "=== Profile Paths ===" -ForegroundColor Cyan
$profilePaths = @{
    'CurrentUserAllHosts' = $PROFILE
    'CurrentUserCurrentHost' = $PROFILE.CurrentUserCurrentHost
    'AllUsersAllHosts' = $PROFILE.AllUsersAllHosts
    'AllUsersCurrentHost' = $PROFILE.AllUsersCurrentHost
}

foreach ($key in $profilePaths.Keys) {
    $path = $profilePaths[$key]
    $exists = Test-Path -LiteralPath $path -ErrorAction SilentlyContinue
    $status = if ($exists) { "EXISTS" } else { "NOT FOUND" }
    $color = if ($exists) { "Green" } else { "Red" }
    Write-Host "  $key : $path" -ForegroundColor Gray
    Write-Host "    Status: $status" -ForegroundColor $color
    if ($exists) {
        $item = Get-Item -LiteralPath $path -ErrorAction SilentlyContinue
        if ($item) {
            Write-Host "    Last Modified: $($item.LastWriteTime)" -ForegroundColor Gray
            Write-Host "    Size: $($item.Length) bytes" -ForegroundColor Gray
        }
    }
    Write-Host ""
}

# Check which profile is actually being used
Write-Host "=== Active Profile ===" -ForegroundColor Cyan
$activeProfile = $PROFILE.CurrentUserCurrentHost
if (Test-Path -LiteralPath $activeProfile) {
    Write-Host "  Path: $activeProfile" -ForegroundColor Green
    Write-Host "  Content Preview (first 10 lines):" -ForegroundColor Yellow
    Get-Content -LiteralPath $activeProfile -TotalCount 10 | ForEach-Object {
        Write-Host "    $_" -ForegroundColor Gray
    }
} else {
    Write-Host "  Profile file not found at: $activeProfile" -ForegroundColor Red
}
Write-Host ""

# Check debug environment variable
Write-Host "=== Debug Settings ===" -ForegroundColor Cyan
if ($env:PS_PROFILE_DEBUG) {
    Write-Host "  PS_PROFILE_DEBUG: $env:PS_PROFILE_DEBUG" -ForegroundColor Green
    $debugLevel = 0
    if ([int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel)) {
        Write-Host "  Parsed Debug Level: $debugLevel" -ForegroundColor Green
    } else {
        Write-Host "  Parsed Debug Level: INVALID (could not parse as integer)" -ForegroundColor Red
    }
} else {
    Write-Host "  PS_PROFILE_DEBUG: NOT SET" -ForegroundColor Yellow
    Write-Host "  To enable debug, set: `$env:PS_PROFILE_DEBUG = '3'" -ForegroundColor Yellow
}
Write-Host ""

# Check host information
Write-Host "=== Host Information ===" -ForegroundColor Cyan
Write-Host "  Host Name: $($Host.Name)" -ForegroundColor Yellow
Write-Host "  Host Version: $($Host.Version)" -ForegroundColor Yellow
if ($Host.UI) {
    Write-Host "  UI Available: Yes" -ForegroundColor Green
    if ($Host.UI.RawUI) {
        Write-Host "  RawUI Available: Yes" -ForegroundColor Green
    } else {
        Write-Host "  RawUI Available: No (non-interactive host)" -ForegroundColor Red
    }
} else {
    Write-Host "  UI Available: No" -ForegroundColor Red
}
Write-Host ""

# Check PSCommandPath
Write-Host "=== Execution Context ===" -ForegroundColor Cyan
if ($PSCommandPath) {
    Write-Host "  PSCommandPath: $PSCommandPath" -ForegroundColor Green
} else {
    Write-Host "  PSCommandPath: EMPTY (profile may exit early)" -ForegroundColor Red
}
Write-Host ""

# Test profile loading with debug
Write-Host "=== Test Profile Loading ===" -ForegroundColor Cyan
Write-Host "  To test profile loading with debug, run:" -ForegroundColor Yellow
Write-Host "    `$env:PS_PROFILE_DEBUG = '3'" -ForegroundColor White
Write-Host "    . `$PROFILE" -ForegroundColor White
Write-Host ""

# Check for common issues
Write-Host "=== Common Issues Check ===" -ForegroundColor Cyan
$issues = @()

if (-not $env:PS_PROFILE_DEBUG) {
    $issues += "PS_PROFILE_DEBUG not set - no debug output will be shown"
}

if (-not $PSCommandPath) {
    $issues += "PSCommandPath is empty - profile will exit early (NoProfile mode)"
}

if (-not $Host.UI -or -not $Host.UI.RawUI) {
    $issues += "Non-interactive host detected - profile will exit early"
}

if (-not (Test-Path -LiteralPath $PROFILE.CurrentUserCurrentHost)) {
    $issues += "Profile file not found at expected location"
}

if ($issues.Count -eq 0) {
    Write-Host "  No obvious issues detected" -ForegroundColor Green
} else {
    Write-Host "  Issues found:" -ForegroundColor Red
    foreach ($issue in $issues) {
        Write-Host "    - $issue" -ForegroundColor Red
    }
}
Write-Host ""

Write-Host "=== End Diagnostics ===" -ForegroundColor Cyan
