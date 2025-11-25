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
# Track profile version and git commit for debugging and support
if (-not $global:PSProfileVersion) {
    $global:PSProfileVersion = '1.0.0'
    $profileDir = Split-Path -Parent $PSCommandPath
    
    # Attempt to get git commit hash if profile is in a git repository
    if (Test-Path (Join-Path $profileDir '.git')) {
        try {
            Push-Location $profileDir -ErrorAction Stop
            try {
                $gitOutput = git rev-parse --short HEAD 2>&1
                if ($LASTEXITCODE -eq 0 -and $gitOutput) {
                    $global:PSProfileGitCommit = $gitOutput.Trim()
                }
                else {
                    $global:PSProfileGitCommit = 'unknown'
                }
            }
            catch {
                $global:PSProfileGitCommit = 'unknown'
            }
            finally {
                Pop-Location -ErrorAction SilentlyContinue
            }
        }
        catch {
            $global:PSProfileGitCommit = 'unknown'
        }
    }
    else {
        $global:PSProfileGitCommit = 'unknown'
    }

    if ($env:PS_PROFILE_DEBUG) {
        Write-Host "PowerShell Profile v$global:PSProfileVersion (commit: $global:PSProfileGitCommit)" -ForegroundColor Cyan
    }
}

# Skip interactive initialization for non-interactive hosts (e.g., automation scripts)
# Non-interactive hosts don't have RawUI, so we exit early to avoid errors
if (-not $Host -or -not $Host.UI -or -not $Host.UI.RawUI) {
    return
}

# PSReadLine is loaded lazily by profile.d/12-psreadline.ps1 to improve startup performance.
# Call Enable-PSReadLine to load PSReadLine with enhanced configuration.

# ===============================================
# PowerShell Profile - Custom Aliases & Functions
# ===============================================
# This profile is intentionally small: feature-rich helpers live in `profile.d/`.

# Environment variables are configured in profile.d/01-env.ps1

# ===============================================
# SCOOP INTEGRATION
# ===============================================
# Dynamically detect and configure Scoop package manager if installed
# Uses ScoopDetection module for detection
$profileDir = Split-Path -Parent $PSCommandPath
$scoopDetectionModule = Join-Path $profileDir 'scripts' 'lib' 'ScoopDetection.psm1'
if (Test-Path $scoopDetectionModule) {
    try {
        Import-Module $scoopDetectionModule -ErrorAction SilentlyContinue -DisableNameChecking
        if (Get-Command Get-ScoopRoot -ErrorAction SilentlyContinue) {
            try {
                $scoopRoot = Get-ScoopRoot
                if ($scoopRoot) {
                    # Import Scoop tab completion if available
                    if (Get-Command Get-ScoopCompletionPath -ErrorAction SilentlyContinue) {
                        try {
                            $scoopCompletion = Get-ScoopCompletionPath -ScoopRoot $scoopRoot
                            if ($scoopCompletion -and (Test-Path $scoopCompletion -ErrorAction SilentlyContinue)) {
                                Import-Module $scoopCompletion -ErrorAction SilentlyContinue
                            }
                        }
                        catch {
                            if ($env:PS_PROFILE_DEBUG) {
                                Write-Verbose "Failed to get Scoop completion path: $($_.Exception.Message)"
                            }
                        }
                    }
                    # Add Scoop shims and bin directories to PATH
                    if (Get-Command Add-ScoopToPath -ErrorAction SilentlyContinue) {
                        try {
                            Add-ScoopToPath -ScoopRoot $scoopRoot | Out-Null
                        }
                        catch {
                            if ($env:PS_PROFILE_DEBUG) {
                                Write-Verbose "Failed to add Scoop to PATH: $($_.Exception.Message)"
                            }
                        }
                    }
                }
            }
            catch {
                if ($env:PS_PROFILE_DEBUG) {
                    Write-Verbose "Failed to get Scoop root: $($_.Exception.Message)"
                }
                # Re-throw to trigger fallback to legacy detection
                throw
            }
        }
        else {
            throw "Get-ScoopRoot command not available after module import"
        }
    }
    catch {
        # Fallback to legacy detection if module fails (checks common Scoop installation paths)
        if ($env:PS_PROFILE_DEBUG) {
            Write-Verbose "ScoopDetection module failed, using legacy detection: $($_.Exception.Message)"
        }
        try {
            # Check global Scoop installation first
            if ($env:SCOOP_GLOBAL -and (Test-Path $env:SCOOP_GLOBAL -ErrorAction SilentlyContinue)) {
                $scoopRoot = $env:SCOOP_GLOBAL
            }
            # Check local Scoop installation
            elseif ($env:SCOOP -and (Test-Path $env:SCOOP -ErrorAction SilentlyContinue)) {
                $scoopRoot = $env:SCOOP
            }
            elseif (Test-Path "$env:USERPROFILE\scoop" -ErrorAction SilentlyContinue) {
                $scoopRoot = "$env:USERPROFILE\scoop"
            }
            elseif (Test-Path "A:\scoop" -ErrorAction SilentlyContinue) {
                $scoopRoot = "A:\scoop"
            }
            if ($scoopRoot) {
                $scoopCompletion = Join-Path $scoopRoot 'apps\scoop\current\supporting\completion\Scoop-Completion.psd1'
                if (Test-Path $scoopCompletion -ErrorAction SilentlyContinue) {
                    Import-Module $scoopCompletion -ErrorAction SilentlyContinue
                }
                # Add Scoop directories to PATH (avoid duplicates)
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
        }
        catch {
            if ($env:PS_PROFILE_DEBUG) {
                Write-Verbose "Legacy Scoop detection also failed: $($_.Exception.Message)"
            }
        }
    }
}

# ===============================================
# FRAGMENT LOADING HELPERS
# ===============================================
# Initialize timing tracking for performance profiling (only when debug mode enabled)
if ($env:PS_PROFILE_DEBUG -and -not $global:PSProfileFragmentTimes) {
    $global:PSProfileFragmentTimes = [System.Collections.Generic.List[PSCustomObject]]::new()
}
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

    # Parse debug level: 0=off, 1=basic, 2=with timing, 3=verbose timing output
    $debugLevel = 0
    if ($env:PS_PROFILE_DEBUG) {
        if (-not [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel)) {
            # Non-numeric value defaults to basic debug
            $debugLevel = 1
        }
    }

    if ($debugLevel -eq 0) {
        & $Action
        return
    }

    # Level 2+: measure and track execution time
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

            # Level 3: display timing information immediately
            if ($debugLevel -ge 3) {
                Write-Host "Fragment '$FragmentName' loaded in $($timing.Duration)ms" -ForegroundColor Cyan
            }
        }
    }
    else {
        # Level 1: basic debug without timing
        & $Action
    }
}

# ===============================================
# LOAD MODULAR PROFILE COMPONENTS
# ===============================================
# Load profile fragments from profile.d/ in dependency-aware order with error handling.
# Fragments can be disabled via configuration or environment variables.
$profileDir = Split-Path -Parent $PSCommandPath
$profileD = Join-Path $profileDir 'profile.d'

# Import fragment management modules for configuration, loading order, and error handling
$fragmentConfigModule = Join-Path $profileDir 'scripts' 'lib' 'FragmentConfig.psm1'
$fragmentLoadingModule = Join-Path $profileDir 'scripts' 'lib' 'FragmentLoading.psm1'
$fragmentErrorHandlingModule = Join-Path $profileDir 'scripts' 'lib' 'FragmentErrorHandling.psm1'

# Initialize fragment configuration (disabled fragments, load order, environment sets, feature flags)
$disabledFragments = @()
$loadOrderOverride = @()
$environmentSets = @{}
$featureFlags = @{}
$performanceConfig = @{ batchLoad = $false; maxFragmentTime = 500 }

if (Test-Path $fragmentConfigModule) {
    try {
        Import-Module $fragmentConfigModule -ErrorAction SilentlyContinue -DisableNameChecking
        $config = Get-FragmentConfig -ProfileDir $profileDir
        $disabledFragments = $config.DisabledFragments
        $loadOrderOverride = $config.LoadOrder
        $environmentSets = $config.Environments
        $featureFlags = $config.FeatureFlags
        $performanceConfig = $config.Performance
    }
    catch {
        if ($env:PS_PROFILE_DEBUG) {
            Write-Host "Warning: Failed to load fragment config module: $($_.Exception.Message)" -ForegroundColor Yellow
        }
    }
}

# Apply environment-specific fragment sets (if PS_PROFILE_ENVIRONMENT is set)
# Environment sets allow loading only specific fragments (useful for CI/CD or minimal profiles)
$currentEnvironment = $env:PS_PROFILE_ENVIRONMENT
if ($currentEnvironment -and $environmentSets.ContainsKey($currentEnvironment)) {
    $allFragments = Get-ChildItem -Path (Join-Path $profileDir 'profile.d') -Filter '*.ps1' -ErrorAction SilentlyContinue
    $enabledFragments = $environmentSets[$currentEnvironment]
    $allFragmentNames = $allFragments | ForEach-Object { $_.BaseName }
    # Disable all fragments except those in the environment set (bootstrap always loads)
    $disabledFragments = $allFragmentNames | Where-Object { $_ -notin $enabledFragments -and $_ -ne '00-bootstrap' }

    if ($env:PS_PROFILE_DEBUG) {
        Write-Host "Environment '$currentEnvironment' active. Enabled fragments: $($enabledFragments -join ', ')" -ForegroundColor Cyan
    }
}

if (Test-Path -LiteralPath (Join-Path $profileDir 'profile.d')) {
    $allFragments = Get-ChildItem -Path $profileD -File -Filter '*.ps1'

    $bootstrapFragment = $allFragments | Where-Object { $_.BaseName -eq '00-bootstrap' }
    $otherFragments = $allFragments | Where-Object { $_.BaseName -ne '00-bootstrap' }

    # Determine fragment load order: use override if specified, otherwise dependency-aware ordering
    if ($loadOrderOverride.Count -gt 0) {
        # Manual load order: load specified fragments first, then remaining fragments alphabetically
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
        # Automatic dependency-aware ordering: analyzes fragment dependencies and loads in correct order
        if (Test-Path $fragmentLoadingModule) {
            try {
                Import-Module $fragmentLoadingModule -ErrorAction SilentlyContinue -DisableNameChecking
                if (Get-Command Get-FragmentLoadOrder -ErrorAction SilentlyContinue) {
                    $nonBootstrapFragments = Get-FragmentLoadOrder -FragmentFiles $otherFragments -DisabledFragments $disabledFragments
                }
                else {
                    $nonBootstrapFragments = $otherFragments | Sort-Object Name
                }
            }
            catch {
                # Fallback to alphabetical if dependency resolution fails
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

    # Batch optimization: group fragments by tier (00-09, 10-29, 30-69, 70-99) for parallel loading
    $enableBatchOptimization = $performanceConfig.batchLoad -or
    $env:PS_PROFILE_BATCH_LOAD -eq '1' -or
    $env:PS_PROFILE_BATCH_LOAD -eq 'true'

    $fragmentsToLoad = [System.Collections.Generic.List[System.IO.FileInfo]]::new()

    # Always load bootstrap first
    if ($bootstrapFragment) {
        foreach ($fragment in $bootstrapFragment) {
            $fragmentsToLoad.Add($fragment)
        }
    }

    if ($enableBatchOptimization) {
        # Group fragments by tier for optimized loading
        if ((Test-Path $fragmentLoadingModule) -and (Get-Command Get-FragmentTiers -ErrorAction SilentlyContinue)) {
            try {
                $tiers = Get-FragmentTiers -FragmentFiles $nonBootstrapFragments -ExcludeBootstrap
                foreach ($fragment in $tiers.Tier0) { $fragmentsToLoad.Add($fragment) }
                foreach ($fragment in $tiers.Tier1) { $fragmentsToLoad.Add($fragment) }
                foreach ($fragment in $tiers.Tier2) { $fragmentsToLoad.Add($fragment) }
                foreach ($fragment in $tiers.Tier3) { $fragmentsToLoad.Add($fragment) }
            }
            catch {
                # Fallback: group by numeric prefix ranges
                $tier0 = $nonBootstrapFragments | Where-Object { $_.BaseName -match '^0[1-9]-' }
                $tier1 = $nonBootstrapFragments | Where-Object { $_.BaseName -match '^(1[0-9]|2[0-9])-' }
                $tier2 = $nonBootstrapFragments | Where-Object { $_.BaseName -match '^([3-6][0-9])-' }
                $tier3 = $nonBootstrapFragments | Where-Object { $_.BaseName -match '^([7-9][0-9])-' }
                foreach ($fragment in $tier0) { $fragmentsToLoad.Add($fragment) }
                foreach ($fragment in $tier1) { $fragmentsToLoad.Add($fragment) }
                foreach ($fragment in $tier2) { $fragmentsToLoad.Add($fragment) }
                foreach ($fragment in $tier3) { $fragmentsToLoad.Add($fragment) }
            }
        }
        else {
            # Fallback: group by numeric prefix ranges
            $tier0 = $nonBootstrapFragments | Where-Object { $_.BaseName -match '^0[1-9]-' }
            $tier1 = $nonBootstrapFragments | Where-Object { $_.BaseName -match '^(1[0-9]|2[0-9])-' }
            $tier2 = $nonBootstrapFragments | Where-Object { $_.BaseName -match '^([3-6][0-9])-' }
            $tier3 = $nonBootstrapFragments | Where-Object { $_.BaseName -match '^([7-9][0-9])-' }
            foreach ($fragment in $tier0) { $fragmentsToLoad.Add($fragment) }
            foreach ($fragment in $tier1) { $fragmentsToLoad.Add($fragment) }
            foreach ($fragment in $tier2) { $fragmentsToLoad.Add($fragment) }
            foreach ($fragment in $tier3) { $fragmentsToLoad.Add($fragment) }
        }
    }
    else {
        # Standard loading: add all fragments in dependency order
        foreach ($fragment in $nonBootstrapFragments) {
            $fragmentsToLoad.Add($fragment)
        }
    }

    foreach ($fragment in $fragmentsToLoad) {
        $fragmentName = $fragment.Name
        $fragmentBaseName = $fragment.BaseName

        # Skip disabled fragments (bootstrap always loads)
        if ($fragmentBaseName -ne '00-bootstrap' -and $disabledSet -and $disabledSet.Contains($fragmentBaseName)) {
            if ($env:PS_PROFILE_DEBUG) { Write-Host "Skipping disabled profile fragment: $fragmentName" -ForegroundColor DarkGray }
            continue
        }

        if ($env:PS_PROFILE_DEBUG) { Write-Host "Loading profile fragment: $fragmentName" -ForegroundColor Cyan }

        # Load fragment with standardized error handling
        if ((Test-Path $fragmentErrorHandlingModule) -and (Get-Command Invoke-FragmentSafely -ErrorAction SilentlyContinue)) {
            $success = Invoke-FragmentSafely -FragmentName $fragmentBaseName -FragmentPath $fragment.FullName
            if (-not $success -and $env:PS_PROFILE_DEBUG) {
                Write-Host "Fragment '$fragmentName' failed to load" -ForegroundColor Red
            }
        }
        else {
            # Fallback: direct execution with manual error handling
            try {
                $null = . $fragment.FullName
            }
            catch {
                # Check if warnings for this fragment should be suppressed
                $suppressFragmentWarning = $false
                if (Get-Command -Name 'Test-FragmentWarningSuppressed' -ErrorAction SilentlyContinue) {
                    try {
                        $suppressFragmentWarning = Test-FragmentWarningSuppressed -FragmentName $fragmentName
                    }
                    catch {
                        $suppressFragmentWarning = $false
                    }
                }

                if ($env:PS_PROFILE_DEBUG) { Write-Host "Failed to load profile fragment '$fragmentName': $($_.Exception.Message)" -ForegroundColor Red }
                if (Get-Command Write-ProfileError -ErrorAction SilentlyContinue) {
                    Write-ProfileError -ErrorRecord $_ -Context "Profile fragment loading" -Category 'Fragment'
                }
                elseif (-not $suppressFragmentWarning) {
                    Write-Warning "Failed to load profile fragment '$fragmentName': $($_.Exception.Message)"
                }
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
# Initialize prompt system (Starship or fallback) if available
# This is called after all fragments load to ensure prompt configuration functions are available
try {
    if ($env:PS_PROFILE_DEBUG) { Write-Host "Checking for Initialize-Starship function..." -ForegroundColor Yellow }
    if (Get-Command Initialize-Starship -ErrorAction SilentlyContinue) {
        if ($env:PS_PROFILE_DEBUG) { Write-Host "Initialize-Starship function found, calling it..." -ForegroundColor Green }
        Initialize-Starship
        if ($env:PS_PROFILE_DEBUG) { Write-Host "Initialize-Starship completed" -ForegroundColor Green }

        # Verify prompt function was created successfully
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
