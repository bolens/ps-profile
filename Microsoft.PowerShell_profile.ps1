<#
    Microsoft.PowerShell_profile.ps1
    Purpose: user profile entrypoint. Keeps initialization minimal and
             delegates large/feature-specific pieces to scripts in
             `profile.d/` so the profile stays modular and easy to
             maintain.

    Notes (existing items are preserved and documented below):
      - Scoop completion import (if present)
      - oh-my-posh initialization (if installed)
      - PSReadLine / history configuration
      - ENV vars for editor/git
      - Ordered, safe loader for `profile.d/*.ps1` (each file should be idempotent)

    All new additions and changes are commented. Keep this file small;
    add functionality in `profile.d/`.
#>

# --- Only run interactive initialization (skip for non-interactive hosts) ---
# If $Host or its RawUI is not available, we're not in an interactive session.
if (-not $Host -or -not $Host.UI -or -not $Host.UI.RawUI) {
    return
}

# --- PSReadLine and command history configuration (improvements + comments) ---
# PSReadLine is now loaded lazily by profile.d/10-psreadline.ps1 to improve startup performance.
# Call Enable-PSReadLine to load PSReadLine with enhanced configuration.

# ===============================================
# PowerShell Profile - Custom Aliases & Functions
# ===============================================
# This profile is intentionally small: feature-rich helpers live in `profile.d/`.

# ===============================================
# ENVIRONMENT VARIABLES (existing)
# ===============================================
# Editor variables used by many tools (keep as existing defaults)
$env:EDITOR = 'code'
$env:GIT_EDITOR = 'code --wait'
$env:VISUAL = 'code'

Import-Module 'A:\scoop\local\apps\scoop\current\supporting\completion\Scoop-Completion.psd1' -ErrorAction SilentlyContinue

# Add scoop shims to PATH so that installed tools are available
$env:PATH = "A:\scoop\shims;A:\scoop\bin;$env:PATH"

# ===============================================
# FRAGMENT LOADING HELPERS
# ===============================================
# Initialize profile timing tracking
if ($env:PS_PROFILE_DEBUG -and -not $global:PSProfileFragmentTimes) {
    $global:PSProfileFragmentTimes = [System.Collections.Generic.List[PSCustomObject]]::new()
}

# Helper function to track fragment load times
<#
.SYNOPSIS
    Measures and tracks the execution time of profile fragments.
.DESCRIPTION
    Wraps the execution of profile fragments to measure their load time.
    Only tracks timing when PS_PROFILE_DEBUG environment variable is set.
    Results are stored in a global list for later analysis.
.PARAMETER FragmentName
    The name of the fragment being measured.
.PARAMETER Action
    The script block to execute and measure.
#>
function Measure-FragmentLoadTime {
    param([string]$FragmentName, [scriptblock]$Action)

    if (-not $env:PS_PROFILE_DEBUG) {
        & $Action
        return
    }

    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    try {
        & $Action
    }
    finally {
        $sw.Stop()
        $global:PSProfileFragmentTimes.Add([PSCustomObject]@{
                Fragment  = $FragmentName
                Duration  = $sw.Elapsed.TotalMilliseconds
                Timestamp = [DateTime]::Now
            })
    }
}

# ===============================================
# LOAD MODULAR PROFILE COMPONENTS (safe, ordered loader)
# ===============================================
# The previous loader dot-sourced all `profile.d/*.ps1` files. To improve
# robustness we load files in sorted order and wrap each load in try/catch.
$profileDir = Split-Path -Parent $PSCommandPath
$profileD = Join-Path $profileDir 'profile.d'
if (Test-Path $profileD) {
    # Load files in lexical order. Each file should be idempotent and
    # safe to be dot-sourced multiple times.
    Get-ChildItem -Path $profileD -File -Filter '*.ps1' | Sort-Object Name | ForEach-Object {
        $fragmentName = $_.Name
        if ($env:PS_PROFILE_DEBUG) { Write-Host "Loading profile fragment: $fragmentName" -ForegroundColor Cyan }
        try {
            # Dot-source the file so it can define functions/aliases in this scope.
            # Assign the result to $null to suppress any returned values (fragments
            # may return ScriptBlocks or other objects during registration). This
            # keeps the profile quiet when opening a new shell.
            $null = . $_.FullName
        }
        catch {
            # Enhanced error handling with recovery suggestions
            if ($env:PS_PROFILE_DEBUG) { Write-Host "Failed to load profile fragment '$fragmentName': $($_.Exception.Message)" -ForegroundColor Red }
            if (Get-Command Write-ProfileError -ErrorAction SilentlyContinue) {
                Write-ProfileError -ErrorRecord $_ -Context "Profile fragment loading" -Category 'Fragment'
            }
            else {
                # Fallback to basic error reporting
                Write-Warning "Failed to load profile fragment '$fragmentName': $($_.Exception.Message)"
            }
        }
    }
}


# ===============================================
# INITIALIZE ENHANCED FEATURES
# ===============================================
# Initialize Starship or smart fallback prompt
try {
    if ($env:PS_PROFILE_DEBUG) { Write-Host "Checking for Initialize-Starship function..." -ForegroundColor Yellow }
    if (Get-Command Initialize-Starship -ErrorAction SilentlyContinue) {
        if ($env:PS_PROFILE_DEBUG) { Write-Host "Initialize-Starship function found, calling it..." -ForegroundColor Green }
        Initialize-Starship
        if ($env:PS_PROFILE_DEBUG) { Write-Host "Initialize-Starship completed" -ForegroundColor Green }
        
        # Final verification: verify prompt function exists (Initialize-Starship handles making it global)
        if (Get-Command prompt -CommandType Function -ErrorAction SilentlyContinue) {
            if ($env:PS_PROFILE_DEBUG) { Write-Host "Prompt function verified and active" -ForegroundColor Green }
        }
        else {
            if ($env:PS_PROFILE_DEBUG) { Write-Host "WARNING: Prompt function not found after initialization!" -ForegroundColor Red }
        }
    }
    else {
        if ($env:PS_PROFILE_DEBUG) { Write-Host "Initialize-Starship function not found" -ForegroundColor Red }
    }
}
catch {
    if ($env:PS_PROFILE_DEBUG) { Write-Host "Initialize-Starship failed: $($_.Exception.Message)" -ForegroundColor Red }
    if (Get-Command Write-ProfileError -ErrorAction SilentlyContinue) {
        Write-ProfileError -ErrorRecord $_ -Context "Prompt initialization" -Category 'Profile'
    }
    else {
        Write-Warning "Failed to initialize prompt: $($_.Exception.Message)"
    }
}
