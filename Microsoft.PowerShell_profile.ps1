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

# ===============================================
# PROFILE VERSION INFORMATION
# ===============================================
# Track profile version for debugging and support
if (-not $global:PSProfileVersion) {
    $global:PSProfileVersion = '1.0.0'
    $profileDir = Split-Path -Parent $PSCommandPath
    if (Test-Path (Join-Path $profileDir '.git')) {
        try {
            Push-Location $profileDir
            $global:PSProfileGitCommit = git rev-parse --short HEAD 2>$null
            Pop-Location
        }
        catch {
            $global:PSProfileGitCommit = 'unknown'
        }
    }
    else {
        $global:PSProfileGitCommit = 'unknown'
    }

    # Display version in debug mode
    if ($env:PS_PROFILE_DEBUG) {
        Write-Host "PowerShell Profile v$global:PSProfileVersion (commit: $global:PSProfileGitCommit)" -ForegroundColor Cyan
    }
}

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
# Editor variables are set in profile.d/01-env.ps1 to avoid duplication
# and ensure proper idempotency checks

# ===============================================
# SCOOP INTEGRATION (dynamic detection)
# ===============================================
# Detect Scoop installation dynamically for portability
$scoopRoot = $null
if ($env:SCOOP) {
    $scoopRoot = $env:SCOOP
}
elseif (Test-Path "$env:USERPROFILE\scoop" -ErrorAction SilentlyContinue) {
    $scoopRoot = "$env:USERPROFILE\scoop"
}
elseif (Test-Path "A:\scoop" -ErrorAction SilentlyContinue) {
    $scoopRoot = "A:\scoop"  # Fallback for legacy setup
}

if ($scoopRoot) {
    # Import Scoop completion module if available
    $scoopCompletion = Join-Path $scoopRoot 'apps\scoop\current\supporting\completion\Scoop-Completion.psd1'
    if (Test-Path $scoopCompletion -ErrorAction SilentlyContinue) {
        Import-Module $scoopCompletion -ErrorAction SilentlyContinue
    }

    # Add Scoop shims and bin to PATH if they exist
    $scoopShims = Join-Path $scoopRoot 'shims'
    $scoopBin = Join-Path $scoopRoot 'bin'
    $pathSeparator = [System.IO.Path]::PathSeparator

    if (Test-Path $scoopShims -ErrorAction SilentlyContinue) {
        if ($env:PATH -notlike "*$([regex]::Escape($scoopShims))*") {
            $env:PATH = "$scoopShims$pathSeparator$env:PATH"
        }
    }
    if (Test-Path $scoopBin -ErrorAction SilentlyContinue) {
        if ($env:PATH -notlike "*$([regex]::Escape($scoopBin))*") {
            $env:PATH = "$scoopBin$pathSeparator$env:PATH"
        }
    }
}

# ===============================================
# FRAGMENT LOADING HELPERS
# ===============================================
# Initialize profile timing tracking
if ($env:PS_PROFILE_DEBUG -and -not $global:PSProfileFragmentTimes) {
    $global:PSProfileFragmentTimes = [System.Collections.Generic.List[PSCustomObject]]::new()
}

# Helper function to track fragment load times with granular debug levels
<#
.SYNOPSIS
    Measures and tracks the execution time of profile fragments.
.DESCRIPTION
    Wraps the execution of profile fragments to measure their load time.
    Supports granular debug levels:
    - PS_PROFILE_DEBUG=1: Basic debug (current behavior)
    - PS_PROFILE_DEBUG=2: Verbose debug (includes timing)
    - PS_PROFILE_DEBUG=3: Performance profiling (detailed metrics)
    Results are stored in a global list for later analysis.
.PARAMETER FragmentName
    The name of the fragment being measured.
.PARAMETER Action
    The script block to execute and measure.
#>
function Measure-FragmentLoadTime {
    param([string]$FragmentName, [scriptblock]$Action)

    # Parse debug level (default to 1 if set but not numeric)
    $debugLevel = 0
    if ($env:PS_PROFILE_DEBUG) {
        if ([int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel)) {
            # Successfully parsed
        }
        else {
            # Non-numeric value means basic debug
            $debugLevel = 1
        }
    }

    if ($debugLevel -eq 0) {
        & $Action
        return
    }

    # Level 2+ includes timing
    if ($debugLevel -ge 2) {
        $sw = [System.Diagnostics.Stopwatch]::StartNew()
        try {
            & $Action
        }
        finally {
            $sw.Stop()
            $timing = [PSCustomObject]@{
                Fragment  = $FragmentName
                Duration  = $sw.Elapsed.TotalMilliseconds
                Timestamp = [DateTime]::Now
            }

            if (-not $global:PSProfileFragmentTimes) {
                $global:PSProfileFragmentTimes = [System.Collections.Generic.List[PSCustomObject]]::new()
            }
            $global:PSProfileFragmentTimes.Add($timing)

            # Level 3 shows detailed output
            if ($debugLevel -ge 3) {
                Write-Host "Fragment '$FragmentName' loaded in $($timing.Duration)ms" -ForegroundColor Cyan
            }
        }
    }
    else {
        # Level 1: basic debug, no timing
        & $Action
    }
}

# ===============================================
# LOAD MODULAR PROFILE COMPONENTS (safe, ordered loader)
# ===============================================
# The previous loader dot-sourced all `profile.d/*.ps1` files. To improve
# robustness we load files in sorted order and wrap each load in try/catch.
# Fragments can be disabled using Disable-ProfileFragment command.
$profileDir = Split-Path -Parent $PSCommandPath
$profileD = Join-Path $profileDir 'profile.d'

# Load fragment configuration (read directly to avoid dependency on bootstrap)
# After bootstrap loads, we'll use Get-FragmentConfig for enhanced features
$fragmentConfigPath = Join-Path $profileDir '.profile-fragments.json'
$disabledFragments = @()
$loadOrderOverride = @()
$environmentSets = @{}
$featureFlags = @{}
$performanceConfig = @{ batchLoad = $false; maxFragmentTime = 500 }

if (Test-Path $fragmentConfigPath) {
    try {
        $configContent = Get-Content -Path $fragmentConfigPath -Raw -ErrorAction Stop
        $configObj = $configContent | ConvertFrom-Json
        if ($configObj.disabled) {
            $disabledFragments = @($configObj.disabled)
        }
        if ($configObj.loadOrder) {
            $loadOrderOverride = @($configObj.loadOrder)
        }
        if ($configObj.environments) {
            # Convert PSCustomObject to hashtable
            $configObj.environments.PSObject.Properties | ForEach-Object {
                $environmentSets[$_.Name] = @($_.Value)
            }
        }
        if ($configObj.featureFlags) {
            $configObj.featureFlags.PSObject.Properties | ForEach-Object {
                $featureFlags[$_.Name] = $_.Value
            }
        }
        if ($configObj.performance) {
            if ($configObj.performance.batchLoad) {
                $performanceConfig.batchLoad = $configObj.performance.batchLoad
            }
            if ($configObj.performance.maxFragmentTime) {
                $performanceConfig.maxFragmentTime = $configObj.performance.maxFragmentTime
            }
        }
    }
    catch {
        if ($env:PS_PROFILE_DEBUG) {
            Write-Host "Warning: Failed to load fragment config: $($_.Exception.Message)" -ForegroundColor Yellow
        }
    }
}

# Check for environment-specific fragment sets
$currentEnvironment = $env:PS_PROFILE_ENVIRONMENT
if ($currentEnvironment -and $environmentSets.ContainsKey($currentEnvironment)) {
    # Disable all fragments, then enable only those in the environment set
    $allFragments = Get-ChildItem -Path (Join-Path $profileDir 'profile.d') -Filter '*.ps1' -ErrorAction SilentlyContinue
    $enabledFragments = $environmentSets[$currentEnvironment]
    $allFragmentNames = $allFragments | ForEach-Object { $_.BaseName }
    $disabledFragments = $allFragmentNames | Where-Object { $_ -notin $enabledFragments -and $_ -ne '00-bootstrap' }

    if ($env:PS_PROFILE_DEBUG) {
        Write-Host "Environment '$currentEnvironment' active. Enabled fragments: $($enabledFragments -join ', ')" -ForegroundColor Cyan
    }
}

if (Test-Path -LiteralPath (Join-Path $profileDir 'profile.d')) {
    $allFragments = Get-ChildItem -Path $profileD -File -Filter '*.ps1'

    $bootstrapFragment = $allFragments | Where-Object { $_.BaseName -eq '00-bootstrap' }
    $otherFragments = $allFragments | Where-Object { $_.BaseName -ne '00-bootstrap' }

    if ($loadOrderOverride.Count -gt 0) {
        $orderedFragments = @()
        $unorderedFragments = @()

        foreach ($fragmentName in $loadOrderOverride) {
            if ($fragmentName -eq '00-bootstrap') { continue }
            $fragment = $otherFragments | Where-Object { $_.BaseName -eq $fragmentName }
            if ($fragment) {
                $orderedFragments += $fragment
            }
        }

        $orderedNames = $orderedFragments | ForEach-Object { $_.BaseName }
        $unorderedFragments = $otherFragments | Where-Object { $_.BaseName -notin $orderedNames } | Sort-Object Name

        $nonBootstrapFragments = $orderedFragments + $unorderedFragments
    }
    else {
        if (Get-Command Get-FragmentLoadOrder -ErrorAction SilentlyContinue) {
            try {
                $nonBootstrapFragments = Get-FragmentLoadOrder -FragmentFiles $otherFragments -DisabledFragments $disabledFragments
            }
            catch {
                $nonBootstrapFragments = $otherFragments | Sort-Object Name
            }
        }
        else {
            $nonBootstrapFragments = $otherFragments | Sort-Object Name
        }
    }

    $disabledSet = $null
    if ($disabledFragments) {
        $disabledSet = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
        foreach ($name in $disabledFragments) {
            if ([string]::IsNullOrWhiteSpace($name)) { continue }
            [void]$disabledSet.Add($name)
        }
    }

    $enableBatchOptimization = $performanceConfig.batchLoad -or
    $env:PS_PROFILE_BATCH_LOAD -eq '1' -or
    $env:PS_PROFILE_BATCH_LOAD -eq 'true'

    $fragmentsToLoad = [System.Collections.Generic.List[System.IO.FileInfo]]::new()

    if ($bootstrapFragment) {
        foreach ($fragment in $bootstrapFragment) {
            $fragmentsToLoad.Add($fragment)
        }
    }

    if ($enableBatchOptimization) {
        $tier0 = $nonBootstrapFragments | Where-Object { $_.BaseName -match '^0[1-9]-' }
        $tier1 = $nonBootstrapFragments | Where-Object { $_.BaseName -match '^(1[0-9]|2[0-9])-' }
        $tier2 = $nonBootstrapFragments | Where-Object { $_.BaseName -match '^([3-6][0-9])-' }
        $tier3 = $nonBootstrapFragments | Where-Object { $_.BaseName -match '^([7-9][0-9])-' }

        foreach ($fragment in $tier0) { $fragmentsToLoad.Add($fragment) }
        foreach ($fragment in $tier1) { $fragmentsToLoad.Add($fragment) }
        foreach ($fragment in $tier2) { $fragmentsToLoad.Add($fragment) }
        foreach ($fragment in $tier3) { $fragmentsToLoad.Add($fragment) }
    }
    else {
        foreach ($fragment in $nonBootstrapFragments) {
            $fragmentsToLoad.Add($fragment)
        }
    }

    foreach ($fragment in $fragmentsToLoad) {
        $fragmentName = $fragment.Name
        $fragmentBaseName = $fragment.BaseName

        if ($fragmentBaseName -ne '00-bootstrap' -and $disabledSet -and $disabledSet.Contains($fragmentBaseName)) {
            if ($env:PS_PROFILE_DEBUG) { Write-Host "Skipping disabled profile fragment: $fragmentName" -ForegroundColor DarkGray }
            continue
        }

        if ($env:PS_PROFILE_DEBUG) { Write-Host "Loading profile fragment: $fragmentName" -ForegroundColor Cyan }

        try {
            $null = . $fragment.FullName
        }
        catch {
            if ($env:PS_PROFILE_DEBUG) { Write-Host "Failed to load profile fragment '$fragmentName': $($_.Exception.Message)" -ForegroundColor Red }
            if (Get-Command Write-ProfileError -ErrorAction SilentlyContinue) {
                Write-ProfileError -ErrorRecord $_ -Context "Profile fragment loading" -Category 'Fragment'
            }
            else {
                Write-Warning "Failed to load profile fragment '$fragmentName': $($_.Exception.Message)"
            }
        }
    }

    if ($enableBatchOptimization -and $env:PS_PROFILE_DEBUG) {
        Write-Host "Batch-optimized loading completed" -ForegroundColor Green
    }
}
else {
    if ($env:PS_PROFILE_DEBUG) {
        Write-Host "Profile fragments directory not found: $profileD" -ForegroundColor Yellow
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
