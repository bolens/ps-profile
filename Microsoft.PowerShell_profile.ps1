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
# NO-PROFILE DETECTION
# ===============================================
# If $PSCommandPath is empty, this profile was likely loaded via a module manifest
# or PowerShell configuration despite -NoProfile being used. Exit early to respect
# the -NoProfile flag. This prevents the profile from loading when -NoProfile is used.
if ([string]::IsNullOrWhiteSpace($PSCommandPath)) {
    # Profile was loaded via non-standard mechanism (likely module manifest)
    # Exit early to respect -NoProfile flag
    return
}

# ===============================================
# TEST-PATH INTERCEPTION (DEBUG MODE ONLY)
# ===============================================
# Intercept Test-Path calls to log null/empty paths when debug mode is enabled
# This helps identify which Test-Path calls are receiving null/empty paths
if ($env:PS_PROFILE_DEBUG_TESTPATH -or $env:PS_PROFILE_DEBUG_TESTPATH_TRACE) {
    $interceptScriptPath = Join-Path (Split-Path -Parent $PSCommandPath) 'scripts' 'utils' 'debug' 'intercept-testpath.ps1'
    if ($interceptScriptPath -and -not [string]::IsNullOrWhiteSpace($interceptScriptPath) -and (Test-Path -LiteralPath $interceptScriptPath)) {
        try {
            . $interceptScriptPath
        }
        catch {
            # Silently fail - interception is optional
            if ($env:PS_PROFILE_DEBUG) {
                Write-Warning "Failed to load Test-Path interception: $($_.Exception.Message)"
            }
        }
    }
}

# ===============================================
# PROFILE VERSION INFORMATION
# ===============================================
# Track profile version and git commit for debugging and support
# Git commit hash is loaded lazily to avoid blocking startup
$profileDir = Split-Path -Parent $PSCommandPath
$profileVersionModule = Join-Path $profileDir 'scripts' 'lib' 'profile' 'ProfileVersion.psm1'
if ($profileVersionModule -and -not [string]::IsNullOrWhiteSpace($profileVersionModule) -and (Test-Path -LiteralPath $profileVersionModule)) {
    try {
        Import-Module $profileVersionModule -ErrorAction SilentlyContinue -DisableNameChecking
        if (Get-Command Initialize-ProfileVersion -ErrorAction SilentlyContinue) {
            Initialize-ProfileVersion -ProfileDir $profileDir
        }
    }
    catch {
        if ($env:PS_PROFILE_DEBUG) {
            Write-Warning "Failed to load ProfileVersion module: $($_.Exception.Message)"
        }
    }
}

# Skip interactive initialization for non-interactive hosts (e.g., automation scripts)
# Non-interactive hosts don't have RawUI, so we exit early to avoid errors
if (-not $Host -or -not $Host.UI -or -not $Host.UI.RawUI) {
    return
}

# PSReadLine is loaded lazily by profile.d/psreadline.ps1 to improve startup performance.
# Call Enable-PSReadLine to load PSReadLine with enhanced configuration.

# ===============================================
# PowerShell Profile - Custom Aliases & Functions
# ===============================================
# This profile is intentionally small: feature-rich helpers live in `profile.d/`.

# Environment variables are configured in profile.d/env.ps1

# ===============================================
# SCOOP INTEGRATION
# ===============================================
# Dynamically detect and configure Scoop package manager if installed
# Uses ProfileScoop module for detection and configuration
if (-not $profileDir) {
    $profileDir = Split-Path -Parent $PSCommandPath
}
$profileScoopModule = Join-Path $profileDir 'scripts' 'lib' 'profile' 'ProfileScoop.psm1'
if ($profileScoopModule -and -not [string]::IsNullOrWhiteSpace($profileScoopModule) -and (Test-Path -LiteralPath $profileScoopModule)) {
    try {
        Import-Module $profileScoopModule -ErrorAction SilentlyContinue -DisableNameChecking
        if (Get-Command Initialize-ProfileScoop -ErrorAction SilentlyContinue) {
            Initialize-ProfileScoop -ProfileDir $profileDir
        }
    }
    catch {
        if ($env:PS_PROFILE_DEBUG) {
            Write-Warning "Failed to load ProfileScoop module: $($_.Exception.Message)"
        }
    }
}

# ===============================================
# FRAGMENT LOADING HELPERS
# ===============================================
# Initialize timing tracking for performance profiling (only when debug mode enabled)
if (-not $profileDir) {
    $profileDir = Split-Path -Parent $PSCommandPath
}
$profileFragmentTimingModule = Join-Path $profileDir 'scripts' 'lib' 'profile' 'ProfileFragmentTiming.psm1'
if ($profileFragmentTimingModule -and -not [string]::IsNullOrWhiteSpace($profileFragmentTimingModule) -and (Test-Path -LiteralPath $profileFragmentTimingModule)) {
    try {
        Import-Module $profileFragmentTimingModule -ErrorAction SilentlyContinue -DisableNameChecking
        if (Get-Command Initialize-FragmentTiming -ErrorAction SilentlyContinue) {
            Initialize-FragmentTiming
        }
    }
    catch {
        if ($env:PS_PROFILE_DEBUG) {
            Write-Warning "Failed to load ProfileFragmentTiming module: $($_.Exception.Message)"
        }
    }
}

# ===============================================
# LOAD .ENV FILES EARLY
# ===============================================
# Load .env files before checking environment variables so that variables like
# PS_PROFILE_PARALLEL_LOADING can be set in .env files
# Note: If $PSCommandPath is empty, we already returned early above, so this should never execute
# with an empty $PSCommandPath, but we check again to be safe
if ([string]::IsNullOrWhiteSpace($PSCommandPath)) {
    return
}
if (-not $profileDir) {
    $profileDir = Split-Path -Parent $PSCommandPath
}
$profileEnvFilesModule = Join-Path $profileDir 'scripts' 'lib' 'profile' 'ProfileEnvFiles.psm1'
if ($profileEnvFilesModule -and -not [string]::IsNullOrWhiteSpace($profileEnvFilesModule) -and (Test-Path -LiteralPath $profileEnvFilesModule)) {
    try {
        Import-Module $profileEnvFilesModule -ErrorAction SilentlyContinue -DisableNameChecking
        if (Get-Command Initialize-ProfileEnvFiles -ErrorAction SilentlyContinue) {
            Initialize-ProfileEnvFiles -ProfileDir $profileDir
        }
    }
    catch {
        if ($env:PS_PROFILE_DEBUG) {
            Write-Warning "Failed to load ProfileEnvFiles module: $($_.Exception.Message)"
        }
    }
}

# ===============================================
# DISPLAY PS_PROFILE ENVIRONMENT VARIABLES (DEBUG)
# ===============================================
$profileEnvDisplayModule = Join-Path $profileDir 'scripts' 'lib' 'profile' 'ProfileEnvDisplay.psm1'
if ($profileEnvDisplayModule -and -not [string]::IsNullOrWhiteSpace($profileEnvDisplayModule) -and (Test-Path -LiteralPath $profileEnvDisplayModule)) {
    try {
        Import-Module $profileEnvDisplayModule -ErrorAction SilentlyContinue -DisableNameChecking
        if (Get-Command Show-ProfileEnvVariables -ErrorAction SilentlyContinue) {
            Show-ProfileEnvVariables
        }
    }
    catch {
        if ($env:PS_PROFILE_DEBUG) {
            Write-Warning "Failed to load ProfileEnvDisplay module: $($_.Exception.Message)"
        }
    }
}

# ===============================================
# LOAD MODULAR PROFILE COMPONENTS
# ===============================================
# Load profile fragments from profile.d/ in dependency-aware order with error handling.
# Fragments can be disabled via configuration or environment variables.
$profileD = Join-Path $profileDir 'profile.d'

# Cache module paths to avoid repeated Join-Path operations
# Initialize $profileDir if not already set (reuse from Scoop section if available)
if (-not $profileDir) {
    $profileDir = Split-Path -Parent $PSCommandPath
}
$scriptsLibDir = Join-Path $profileDir 'scripts' 'lib'
$fragmentLibDir = Join-Path $scriptsLibDir 'fragment'
$fragmentConfigModule = Join-Path $fragmentLibDir 'FragmentConfig.psm1'
$fragmentLoadingModule = Join-Path $fragmentLibDir 'FragmentLoading.psm1'
$fragmentErrorHandlingModule = Join-Path $fragmentLibDir 'FragmentErrorHandling.psm1'
# Initialize Test-Path cache variables
$fragmentErrorHandlingModuleExists = if ($fragmentErrorHandlingModule -and -not [string]::IsNullOrWhiteSpace($fragmentErrorHandlingModule)) { Test-Path -LiteralPath $fragmentErrorHandlingModule } else { $false }

# Load fragment configuration module
$profileFragmentConfigModule = Join-Path $profileDir 'scripts' 'lib' 'profile' 'ProfileFragmentConfig.psm1'
if ($profileFragmentConfigModule -and -not [string]::IsNullOrWhiteSpace($profileFragmentConfigModule) -and (Test-Path -LiteralPath $profileFragmentConfigModule)) {
    try {
        Import-Module $profileFragmentConfigModule -ErrorAction SilentlyContinue -DisableNameChecking
        if (Get-Command Initialize-FragmentConfiguration -ErrorAction SilentlyContinue) {
            $fragmentConfig = Initialize-FragmentConfiguration -ProfileDir $profileDir -FragmentConfigModule $fragmentConfigModule
            $disabledFragments = $fragmentConfig.DisabledFragments
            $loadOrderOverride = $fragmentConfig.LoadOrderOverride
            $environmentSets = $fragmentConfig.EnvironmentSets
            $featureFlags = $fragmentConfig.FeatureFlags
            $performanceConfig = $fragmentConfig.PerformanceConfig
            $allFragments = $fragmentConfig.AllFragments
            $profileDExists = $fragmentConfig.ProfileDExists
            $profileD = $fragmentConfig.ProfileD
            $fragmentLoadingModule = $fragmentConfig.FragmentLoadingModule
            $fragmentLibDir = $fragmentConfig.FragmentLibDir
        }
        # Ensure Test-EnvBool is available
        if (-not (Get-Command Test-EnvBool -ErrorAction SilentlyContinue)) {
            Import-Module $profileFragmentConfigModule -Force -ErrorAction SilentlyContinue -DisableNameChecking
        }
    }
    catch {
        if ($env:PS_PROFILE_DEBUG) {
            Write-Warning "Failed to load ProfileFragmentConfig module: $($_.Exception.Message)"
        }
        # Fallback to empty configuration
        $disabledFragments = @()
        $loadOrderOverride = @()
        $environmentSets = @{}
        $featureFlags = @{}
        $performanceConfig = @{ 
            maxFragmentTime           = 500
            parallelDependencyParsing = $true
        }
        $allFragments = $null
        $profileDExists = $false
        $fragmentLoadingModule = $null
        $fragmentLibDir = Join-Path $profileDir 'scripts' 'lib' 'fragment'
    }
}
else {
    # Fallback if module doesn't exist
    $disabledFragments = @()
    $loadOrderOverride = @()
    $environmentSets = @{}
    $featureFlags = @{}
    $performanceConfig = @{ 
        maxFragmentTime           = 500
        parallelDependencyParsing = $true
    }
    $allFragments = $null
    $profileDExists = if ($profileD -and -not [string]::IsNullOrWhiteSpace($profileD)) { Test-Path -LiteralPath $profileD } else { $false }
    if ($profileDExists) {
        $allFragments = Get-ChildItem -Path $profileD -File -Filter '*.ps1' -ErrorAction SilentlyContinue | 
        Where-Object { 
            if ($env:PS_PROFILE_TEST_MODE) { return $true }
            $_.BaseName -notmatch '-test-'
        }
    }
    $fragmentLoadingModule = Join-Path $profileDir 'scripts' 'lib' 'fragment' 'FragmentLoading.psm1'
    $fragmentLibDir = Join-Path $profileDir 'scripts' 'lib' 'fragment'
}

# Helper function to normalize boolean environment variables (fallback if module not loaded)
# Supports: '1', 'true' (case-insensitive) -> $true
#           '0', 'false' (case-insensitive), empty/null -> $false
if (-not (Get-Command Test-EnvBool -ErrorAction SilentlyContinue)) {
    function Test-EnvBool {
        param([string]$Value)
        if ([string]::IsNullOrWhiteSpace($Value)) {
            return $false
        }
        $normalized = $Value.Trim().ToLowerInvariant()
        return ($normalized -eq '1' -or $normalized -eq 'true')
    }
}

if ($profileDExists -and $allFragments) {
    # Load fragment discovery module
    $profileFragmentDiscoveryModule = Join-Path $profileDir 'scripts' 'lib' 'profile' 'ProfileFragmentDiscovery.psm1'
    $fragmentLoadingModuleExists = if ($fragmentLoadingModule -and -not [string]::IsNullOrWhiteSpace($fragmentLoadingModule)) { Test-Path -LiteralPath $fragmentLoadingModule } else { $false }
    $enableParallelLoading = Test-EnvBool -Value $env:PS_PROFILE_PARALLEL_LOADING
    
    if ($profileFragmentDiscoveryModule -and -not [string]::IsNullOrWhiteSpace($profileFragmentDiscoveryModule) -and (Test-Path -LiteralPath $profileFragmentDiscoveryModule)) {
        try {
            Import-Module $profileFragmentDiscoveryModule -ErrorAction SilentlyContinue -DisableNameChecking
            if (Get-Command Initialize-FragmentDiscovery -ErrorAction SilentlyContinue) {
                $discoveryResult = Initialize-FragmentDiscovery `
                    -AllFragments $allFragments `
                    -LoadOrderOverride $loadOrderOverride `
                    -DisabledFragments $disabledFragments `
                    -FragmentLoadingModule $fragmentLoadingModule `
                    -FragmentLoadingModuleExists $fragmentLoadingModuleExists `
                    -EnableParallelLoading $enableParallelLoading `
                    -PerformanceConfig $performanceConfig `
                    -FragmentLibDir $fragmentLibDir
                
                $bootstrapFragment = $discoveryResult.BootstrapFragment
                $fragmentsToLoad = $discoveryResult.FragmentsToLoad
                $disabledSet = $discoveryResult.DisabledSet
                $nonBootstrapFragments = $discoveryResult.NonBootstrapFragments
            }
        }
        catch {
            if ($env:PS_PROFILE_DEBUG) {
                Write-Warning "Failed to load ProfileFragmentDiscovery module: $($_.Exception.Message)"
            }
            # Fallback: use simple alphabetical ordering
            $bootstrapFragment = @()
            $fragmentsToLoad = [System.Collections.Generic.List[System.IO.FileInfo]]::new()
            $disabledSet = $null
            if ($disabledFragments) {
                $disabledSet = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
                foreach ($name in $disabledFragments) {
                    if ([string]::IsNullOrWhiteSpace($name)) { continue }
                    [void]$disabledSet.Add($name)
                }
            }
            foreach ($fragment in ($allFragments | Sort-Object Name)) {
                $fragmentsToLoad.Add($fragment)
            }
        }
    }
    else {
        # Fallback: use simple alphabetical ordering
        $bootstrapFragment = @()
        $fragmentsToLoad = [System.Collections.Generic.List[System.IO.FileInfo]]::new()
        $disabledSet = $null
        if ($disabledFragments) {
            $disabledSet = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
            foreach ($name in $disabledFragments) {
                if ([string]::IsNullOrWhiteSpace($name)) { continue }
                [void]$disabledSet.Add($name)
            }
        }
        foreach ($fragment in ($allFragments | Sort-Object Name)) {
            $fragmentsToLoad.Add($fragment)
        }
    }

    # Load fragments using parallel or sequential approach
    $profileFragmentLoaderModule = Join-Path $profileDir 'scripts' 'lib' 'profile' 'ProfileFragmentLoader.psm1'
    
    if ($profileFragmentLoaderModule -and -not [string]::IsNullOrWhiteSpace($profileFragmentLoaderModule) -and (Test-Path -LiteralPath $profileFragmentLoaderModule)) {
        try {
            Import-Module $profileFragmentLoaderModule -ErrorAction SilentlyContinue -DisableNameChecking
            if (Get-Command Initialize-FragmentLoading -ErrorAction SilentlyContinue) {
                Initialize-FragmentLoading `
                    -FragmentsToLoad $fragmentsToLoad `
                    -BootstrapFragment $bootstrapFragment `
                    -DisabledSet $disabledSet `
                    -DisabledFragments $disabledFragments `
                    -EnableParallelLoading $enableParallelLoading `
                    -FragmentLoadingModule $fragmentLoadingModule `
                    -FragmentLoadingModuleExists $fragmentLoadingModuleExists `
                    -FragmentLibDir $fragmentLibDir `
                    -FragmentErrorHandlingModule $fragmentErrorHandlingModule `
                    -FragmentErrorHandlingModuleExists $fragmentErrorHandlingModuleExists `
                    -ProfileD $profileD
            }
        }
        catch {
            if ($env:PS_PROFILE_DEBUG) {
                $posMsg = $null
                try {
                    if ($_.InvocationInfo -and $_.InvocationInfo.PositionMessage) {
                        $posMsg = $_.InvocationInfo.PositionMessage.Trim()
                    }
                }
                catch {
                    $posMsg = $null
                }

                if ($posMsg) {
                    Write-Warning ("Failed to load ProfileFragmentLoader module: {0}`n{1}" -f $_.Exception.Message, $posMsg)
                }
                else {
                    Write-Warning "Failed to load ProfileFragmentLoader module: $($_.Exception.Message)"
                }
            }
            # Fallback: use simple sequential loading
            $fallbackLoadedFragments = [System.Collections.Generic.List[string]]::new()
            $fallbackBatchSize = 10
            foreach ($fragment in $fragmentsToLoad) {
                $fragmentName = $fragment.Name
                $fragmentBaseName = $fragment.BaseName

                # Skip disabled fragments (bootstrap always loads)
                if ($fragmentBaseName -ne 'bootstrap' -and $disabledSet -and $disabledSet.Contains($fragmentBaseName)) {
                    continue
                }

                if ($env:PS_PROFILE_DEBUG) {
                    $showIndividualFragments = $false
                    if ($env:PS_PROFILE_DEBUG_SHOW_INDIVIDUAL_FRAGMENTS) {
                        $normalized = $env:PS_PROFILE_DEBUG_SHOW_INDIVIDUAL_FRAGMENTS.Trim().ToLowerInvariant()
                        $showIndividualFragments = ($normalized -eq '1' -or $normalized -eq 'true')
                    }
                    
                    if ($showIndividualFragments) {
                        Write-Host "Loading profile fragment: $fragmentName" -ForegroundColor Cyan
                    }
                    else {
                        $fallbackLoadedFragments.Add($fragmentBaseName)
                        if ($fallbackLoadedFragments.Count % $fallbackBatchSize -eq 0) {
                            $batchStart = [Math]::Max(0, $fallbackLoadedFragments.Count - $fallbackBatchSize)
                            $batch = $fallbackLoadedFragments[$batchStart..($fallbackLoadedFragments.Count - 1)]
                            $fragmentList = ($batch -join ', ')
                            Write-Host "Loading fragments ($($fallbackLoadedFragments.Count) total): $fragmentList" -ForegroundColor Cyan
                        }
                    }
                }

                $originalProfileFragmentRoot = $global:ProfileFragmentRoot
                if ($fragment -and $fragment.DirectoryName) {
                    $global:ProfileFragmentRoot = $fragment.DirectoryName
                }
                try {
                    $null = . $fragment.FullName
                }
                catch {
                    if ($env:PS_PROFILE_DEBUG) {
                        Write-Host "Failed to load profile fragment '$fragmentName': $($_.Exception.Message)" -ForegroundColor Red
                    }
                    Write-Warning "Failed to load profile fragment '$fragmentName': $($_.Exception.Message)"
                }
                finally {
                    $global:ProfileFragmentRoot = $originalProfileFragmentRoot
                }
            }
            
            # Show remaining fragments if batching
            if ($env:PS_PROFILE_DEBUG -and $fallbackLoadedFragments.Count -gt 0) {
                $showIndividualFragments = $false
                if ($env:PS_PROFILE_DEBUG_SHOW_INDIVIDUAL_FRAGMENTS) {
                    $normalized = $env:PS_PROFILE_DEBUG_SHOW_INDIVIDUAL_FRAGMENTS.Trim().ToLowerInvariant()
                    $showIndividualFragments = ($normalized -eq '1' -or $normalized -eq 'true')
                }
                
                if (-not $showIndividualFragments) {
                    $remainingCount = $fallbackLoadedFragments.Count % $fallbackBatchSize
                    if ($remainingCount -gt 0) {
                        $batchStart = $fallbackLoadedFragments.Count - $remainingCount
                        $batch = $fallbackLoadedFragments[$batchStart..($fallbackLoadedFragments.Count - 1)]
                        $fragmentList = ($batch -join ', ')
                        Write-Host "Loading fragments ($($fallbackLoadedFragments.Count) total): $fragmentList" -ForegroundColor Cyan
                    }
                    Write-Host ""
                    Write-Host "Loaded $($fallbackLoadedFragments.Count) fragments successfully" -ForegroundColor Green
                }
            }
        }
    }
    else {
        # Fallback: use simple sequential loading
        $fallbackLoadedFragments2 = [System.Collections.Generic.List[string]]::new()
        $fallbackBatchSize2 = 10
        foreach ($fragment in $fragmentsToLoad) {
            $fragmentName = $fragment.Name
            $fragmentBaseName = $fragment.BaseName

            # Skip disabled fragments (bootstrap always loads)
            if ($fragmentBaseName -ne 'bootstrap' -and $disabledSet -and $disabledSet.Contains($fragmentBaseName)) {
                continue
            }

            if ($env:PS_PROFILE_DEBUG) {
                $showIndividualFragments = $false
                if ($env:PS_PROFILE_DEBUG_SHOW_INDIVIDUAL_FRAGMENTS) {
                    $normalized = $env:PS_PROFILE_DEBUG_SHOW_INDIVIDUAL_FRAGMENTS.Trim().ToLowerInvariant()
                    $showIndividualFragments = ($normalized -eq '1' -or $normalized -eq 'true')
                }
                
                if ($showIndividualFragments) {
                    Write-Host "Loading profile fragment: $fragmentName" -ForegroundColor Cyan
                }
                else {
                    $fallbackLoadedFragments2.Add($fragmentBaseName)
                    if ($fallbackLoadedFragments2.Count % $fallbackBatchSize2 -eq 0) {
                        $batchStart = [Math]::Max(0, $fallbackLoadedFragments2.Count - $fallbackBatchSize2)
                        $batch = $fallbackLoadedFragments2[$batchStart..($fallbackLoadedFragments2.Count - 1)]
                        $fragmentList = ($batch -join ', ')
                        Write-Host "Loading fragments ($($fallbackLoadedFragments2.Count) total): $fragmentList" -ForegroundColor Cyan
                    }
                }
            }

            $originalProfileFragmentRoot = $global:ProfileFragmentRoot
            if ($fragment -and $fragment.DirectoryName) {
                $global:ProfileFragmentRoot = $fragment.DirectoryName
            }
            try {
                $null = . $fragment.FullName
            }
            catch {
                if ($env:PS_PROFILE_DEBUG) {
                    Write-Host "Failed to load profile fragment '$fragmentName': $($_.Exception.Message)" -ForegroundColor Red
                }
                Write-Warning "Failed to load profile fragment '$fragmentName': $($_.Exception.Message)"
            }
            finally {
                $global:ProfileFragmentRoot = $originalProfileFragmentRoot
            }
        }
        
        # Show remaining fragments if batching
        if ($env:PS_PROFILE_DEBUG -and $fallbackLoadedFragments2.Count -gt 0) {
            $showIndividualFragments = $false
            if ($env:PS_PROFILE_DEBUG_SHOW_INDIVIDUAL_FRAGMENTS) {
                $normalized = $env:PS_PROFILE_DEBUG_SHOW_INDIVIDUAL_FRAGMENTS.Trim().ToLowerInvariant()
                $showIndividualFragments = ($normalized -eq '1' -or $normalized -eq 'true')
            }
            
            if (-not $showIndividualFragments) {
                $remainingCount = $fallbackLoadedFragments2.Count % $fallbackBatchSize2
                if ($remainingCount -gt 0) {
                    $batchStart = $fallbackLoadedFragments2.Count - $remainingCount
                    $batch = $fallbackLoadedFragments2[$batchStart..($fallbackLoadedFragments2.Count - 1)]
                    $fragmentList = ($batch -join ', ')
                    Write-Host "Loading fragments ($($fallbackLoadedFragments2.Count) total): $fragmentList" -ForegroundColor Cyan
                }
                Write-Host ""
                Write-Host "Loaded $($fallbackLoadedFragments2.Count) fragments successfully" -ForegroundColor Green
            }
        }
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
$profilePromptModule = Join-Path $profileDir 'scripts' 'lib' 'profile' 'ProfilePrompt.psm1'
if ($profilePromptModule -and -not [string]::IsNullOrWhiteSpace($profilePromptModule) -and (Test-Path -LiteralPath $profilePromptModule)) {
    try {
        Import-Module $profilePromptModule -ErrorAction SilentlyContinue -DisableNameChecking
        if (Get-Command Initialize-ProfilePrompt -ErrorAction SilentlyContinue) {
            Initialize-ProfilePrompt
        }
    }
    catch {
        if ($env:PS_PROFILE_DEBUG) {
            Write-Warning "Failed to load ProfilePrompt module: $($_.Exception.Message)"
        }
    }
}

# ===============================================
# DISPLAY BATCH LOADING SUMMARY
# ===============================================
# Show organized batch loading summary
try {
    if (Get-Command Show-BatchLoadingSummary -ErrorAction SilentlyContinue) {
        Show-BatchLoadingSummary
    }
}
catch {
    if ($env:PS_PROFILE_DEBUG) {
        Write-Host "Failed to display batch loading summary: $($_.Exception.Message)" -ForegroundColor Yellow
    }
}

# ===============================================
# DISPLAY MISSING TOOL WARNINGS
# ===============================================
# Show collected missing tool warnings in a single table
try {
    if (Get-Command Show-MissingToolWarningsTable -ErrorAction SilentlyContinue) {
        Show-MissingToolWarningsTable
    }
}
catch {
    if ($env:PS_PROFILE_DEBUG) {
        Write-Host "Failed to display missing tool warnings table: $($_.Exception.Message)" -ForegroundColor Yellow
    }
}
