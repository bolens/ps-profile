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
# FILE-BASED LOGGING (IMMEDIATE - BEFORE ANYTHING)
# ===============================================
# Write to a log file immediately to track where profile execution stops
# This works even if console output is blocked or profile hangs
$profileLogFile = Join-Path $env:TEMP "powershell-profile-load.log"
try {
    $logEntry = "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] Profile execution started"
    $logEntry | Out-File -FilePath $profileLogFile -Append -Encoding UTF8 -ErrorAction SilentlyContinue
}
catch {
    # Ignore logging errors - we can't do anything about them
}

# ===============================================
# LOAD .ENV FILES FIRST (BEFORE DEBUG CHECKS)
# ===============================================
# Load .env files BEFORE checking debug level so that PS_PROFILE_DEBUG from .env is available
# This ensures debug output works on initial startup when PS_PROFILE_DEBUG is set in .env
if (-not [string]::IsNullOrWhiteSpace($PSCommandPath)) {
    $profileDir = Split-Path -Parent $PSCommandPath
    $profileEnvFilesModule = Join-Path $profileDir 'scripts' 'lib' 'profile' 'ProfileEnvFiles.psm1'
    if ($profileEnvFilesModule -and -not [string]::IsNullOrWhiteSpace($profileEnvFilesModule) -and (Test-Path -LiteralPath $profileEnvFilesModule)) {
        try {
            # Log PS_PROFILE_DEBUG value BEFORE loading .env files
            try {
                "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] Before .env load: PS_PROFILE_DEBUG='$($env:PS_PROFILE_DEBUG)'" | Out-File -FilePath $profileLogFile -Append -Encoding UTF8 -ErrorAction SilentlyContinue
            }
            catch { }
            
            Import-Module $profileEnvFilesModule -ErrorAction SilentlyContinue -DisableNameChecking
            if (Get-Command Initialize-ProfileEnvFiles -ErrorAction SilentlyContinue) {
                Initialize-ProfileEnvFiles -ProfileDir $profileDir
                
                # Log PS_PROFILE_DEBUG value AFTER loading .env files
                try {
                    "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] After .env load: PS_PROFILE_DEBUG='$($env:PS_PROFILE_DEBUG)'" | Out-File -FilePath $profileLogFile -Append -Encoding UTF8 -ErrorAction SilentlyContinue
                }
                catch { }
            }
        }
        catch {
            # Silently fail - .env loading shouldn't block profile startup
            try {
                "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] Failed to load ProfileEnvFiles module: $($_.Exception.Message)" | Out-File -FilePath $profileLogFile -Append -Encoding UTF8 -ErrorAction SilentlyContinue
            }
            catch { }
        }
    }
}

# ===============================================
# PROFILE STARTUP LOGGING
# ===============================================
# Log profile startup immediately (before any checks) if debug is enabled
# This helps diagnose if the profile file is being executed at all
try {
    if ($env:PS_PROFILE_DEBUG) {
        $initialDebugLevel = 0
        if ([int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$initialDebugLevel) -and $initialDebugLevel -ge 1) {
            $msg = "[profile] Profile startup detected - PSCommandPath: $PSCommandPath"
            # Use Write-Host instead of Write-Output for initial startup visibility
            # Write-Host writes directly to console, bypassing output stream buffering
            try {
                Write-Host $msg -ForegroundColor Cyan
            }
            catch {
                # Fallback to Write-Output if Write-Host fails (non-interactive host)
                Write-Output $msg
            }
            try {
                "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] $msg" | Out-File -FilePath $profileLogFile -Append -Encoding UTF8 -ErrorAction SilentlyContinue
            }
            catch { }
        }
    }
    else {
        try {
            "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] Profile startup (PSCommandPath: $PSCommandPath, Debug: NOT SET)" | Out-File -FilePath $profileLogFile -Append -Encoding UTF8 -ErrorAction SilentlyContinue
        }
        catch { }
    }
}
catch {
    try {
        "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] Error in startup logging: $($_.Exception.Message)" | Out-File -FilePath $profileLogFile -Append -Encoding UTF8 -ErrorAction SilentlyContinue
    }
    catch { }
}

# ===============================================
# DEBUG MODE SETUP (EARLY - BEFORE ANY CHECKS)
# ===============================================
# Parse debug level immediately so we can use it for all early exit logging
try {
    $debugLevel = 0
    $debugValue = $env:PS_PROFILE_DEBUG
    $parseSuccess = $false
    
    # Always log the raw value for diagnostics
    try {
        "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] Debug check: PS_PROFILE_DEBUG='$debugValue' (type: $($debugValue.GetType().Name))" | Out-File -FilePath $profileLogFile -Append -Encoding UTF8 -ErrorAction SilentlyContinue
    }
    catch { }
    
    if ($debugValue -and [int]::TryParse($debugValue, [ref]$debugLevel)) {
        $parseSuccess = $true
        try {
            "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] Debug parsed: level=$debugLevel" | Out-File -FilePath $profileLogFile -Append -Encoding UTF8 -ErrorAction SilentlyContinue
        }
        catch { }
        
        if ($debugLevel -ge 1) {
            # Enable verbose output for Write-Verbose debug messages (set globally so all modules see it)
            $global:VerbosePreference = 'Continue'
            $VerbosePreference = 'Continue'  # Also set in script scope for immediate use
            
            # Use Write-Host for early debug messages (more reliable during initial startup)
            # Write-Host writes directly to console, bypassing output stream buffering
            $msg = "[profile] Debug mode enabled (level $debugLevel)"
            try {
                Write-Host $msg -ForegroundColor Green
            }
            catch {
                # Fallback to Write-Output if Write-Host fails (non-interactive host)
                Write-Output $msg
            }
            try {
                "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] $msg" | Out-File -FilePath $profileLogFile -Append -Encoding UTF8 -ErrorAction SilentlyContinue
            }
            catch { }
            
            # Level 3: Show diagnostic information
            if ($debugLevel -ge 3) {
                Write-Host "  [profile.debug] ✓ Debug level 3 detected and enabled" -ForegroundColor Green
                Write-Host "  [profile.debug] VerbosePreference (global): $($global:VerbosePreference)" -ForegroundColor DarkGray
                Write-Host "  [profile.debug] VerbosePreference (script): $VerbosePreference" -ForegroundColor DarkGray
                Write-Host "  [profile.debug] Environment variable PS_PROFILE_DEBUG='$debugValue'" -ForegroundColor DarkGray
                Write-Host "  [profile.debug] All Write-Verbose messages will now be displayed" -ForegroundColor DarkGray
            }
        }
    }
    else {
        try {
            $reason = if (-not $debugValue) { "not set" } elseif (-not $parseSuccess) { "parse failed" } else { "level < 1" }
            "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] Debug mode check: PS_PROFILE_DEBUG='$debugValue' - $reason" | Out-File -FilePath $profileLogFile -Append -Encoding UTF8 -ErrorAction SilentlyContinue
        }
        catch { }
    }
}
catch {
    try {
        "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] Error in debug setup: $($_.Exception.Message)" | Out-File -FilePath $profileLogFile -Append -Encoding UTF8 -ErrorAction SilentlyContinue
    }
    catch { }
}

# ===============================================
# NO-PROFILE DETECTION
# ===============================================
# If $PSCommandPath is empty, this profile was likely loaded via a module manifest
# or PowerShell configuration despite -NoProfile being used. Exit early to respect
# the -NoProfile flag. This prevents the profile from loading when -NoProfile is used.
try {
    if ([string]::IsNullOrWhiteSpace($PSCommandPath)) {
        # Profile was loaded via non-standard mechanism (likely module manifest)
        # Exit early to respect -NoProfile flag
        $msg = "[profile] Early exit: PSCommandPath is empty (NoProfile detected)"
        if ($debugLevel -ge 1) {
            try {
                Write-Host $msg -ForegroundColor Yellow
            }
            catch {
                # Fallback to Write-Output if Write-Host fails (non-interactive host)
                Write-Output $msg
            }
        }
        try {
            "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] $msg" | Out-File -FilePath $profileLogFile -Append -Encoding UTF8 -ErrorAction SilentlyContinue
        }
        catch { }
        return
    }
    else {
        try {
            "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] PSCommandPath check passed: $PSCommandPath" | Out-File -FilePath $profileLogFile -Append -Encoding UTF8 -ErrorAction SilentlyContinue
        }
        catch { }
    }
}
catch {
    try {
        "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] Error in NoProfile detection: $($_.Exception.Message)" | Out-File -FilePath $profileLogFile -Append -Encoding UTF8 -ErrorAction SilentlyContinue
    }
    catch { }
}

# ===============================================
# TEST-PATH INTERCEPTION (DEBUG MODE ONLY)
# ===============================================
# Intercept Test-Path calls to log null/empty paths when debug mode is enabled
# This helps identify which Test-Path calls are receiving null/empty paths
try {
    try {
        "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] Before Test-Path interception check" | Out-File -FilePath $profileLogFile -Append -Encoding UTF8 -ErrorAction SilentlyContinue
    }
    catch { }
    
    if ($env:PS_PROFILE_DEBUG_TESTPATH -or $env:PS_PROFILE_DEBUG_TESTPATH_TRACE) {
        try {
            "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] Test-Path interception enabled, checking script path" | Out-File -FilePath $profileLogFile -Append -Encoding UTF8 -ErrorAction SilentlyContinue
        }
        catch { }
        
        $interceptScriptPath = Join-Path (Split-Path -Parent $PSCommandPath) 'scripts' 'utils' 'debug' 'intercept-testpath.ps1'
        
        try {
            "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] Intercept script path: $interceptScriptPath" | Out-File -FilePath $profileLogFile -Append -Encoding UTF8 -ErrorAction SilentlyContinue
        }
        catch { }
        
        if ($interceptScriptPath -and -not [string]::IsNullOrWhiteSpace($interceptScriptPath)) {
            # Use Microsoft.PowerShell.Management\Test-Path to avoid potential recursion if interception is already active
            $interceptExists = $false
            try {
                $interceptExists = Microsoft.PowerShell.Management\Test-Path -LiteralPath $interceptScriptPath -ErrorAction SilentlyContinue
            }
            catch {
                try {
                    "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] Error checking intercept script path: $($_.Exception.Message)" | Out-File -FilePath $profileLogFile -Append -Encoding UTF8 -ErrorAction SilentlyContinue
                }
                catch { }
            }
            
            if ($interceptExists) {
                try {
                    "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] Loading Test-Path interception script" | Out-File -FilePath $profileLogFile -Append -Encoding UTF8 -ErrorAction SilentlyContinue
                }
                catch { }
                
                try {
                    . $interceptScriptPath
                    try {
                        "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] Test-Path interception script loaded successfully" | Out-File -FilePath $profileLogFile -Append -Encoding UTF8 -ErrorAction SilentlyContinue
                    }
                    catch { }
                }
                catch {
                    # Silently fail - interception is optional
                    try {
                        "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] Failed to load Test-Path interception: $($_.Exception.Message)" | Out-File -FilePath $profileLogFile -Append -Encoding UTF8 -ErrorAction SilentlyContinue
                    }
                    catch { }
                    if ($env:PS_PROFILE_DEBUG) {
                        Write-Warning "Failed to load Test-Path interception: $($_.Exception.Message)"
                    }
                }
            }
            else {
                try {
                    "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] Test-Path interception script not found at: $interceptScriptPath" | Out-File -FilePath $profileLogFile -Append -Encoding UTF8 -ErrorAction SilentlyContinue
                }
                catch { }
            }
        }
    }
    else {
        try {
            "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] Test-Path interception not enabled" | Out-File -FilePath $profileLogFile -Append -Encoding UTF8 -ErrorAction SilentlyContinue
        }
        catch { }
    }
}
catch {
    try {
        "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] Error in Test-Path interception section: $($_.Exception.Message)" | Out-File -FilePath $profileLogFile -Append -Encoding UTF8 -ErrorAction SilentlyContinue
    }
    catch { }
}

# ===============================================
# PROFILE VERSION INFORMATION
# ===============================================
# Track profile version and git commit for debugging and support
# Git commit hash is loaded lazily to avoid blocking startup
try {
    try {
        "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] Before profile version section" | Out-File -FilePath $profileLogFile -Append -Encoding UTF8 -ErrorAction SilentlyContinue
    }
    catch { }
    
    $profileDir = Split-Path -Parent $PSCommandPath
    $profileVersionModule = Join-Path $profileDir 'scripts' 'lib' 'profile' 'ProfileVersion.psm1'
    
    try {
        "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] ProfileDir: $profileDir, VersionModule: $profileVersionModule" | Out-File -FilePath $profileLogFile -Append -Encoding UTF8 -ErrorAction SilentlyContinue
    }
    catch { }
    
    if ($profileVersionModule -and -not [string]::IsNullOrWhiteSpace($profileVersionModule)) {
        # Use Microsoft.PowerShell.Management\Test-Path to avoid potential issues
        $versionModuleExists = $false
        try {
            $versionModuleExists = Microsoft.PowerShell.Management\Test-Path -LiteralPath $profileVersionModule -ErrorAction SilentlyContinue
        }
        catch {
            try {
                "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] Error checking version module path: $($_.Exception.Message)" | Out-File -FilePath $profileLogFile -Append -Encoding UTF8 -ErrorAction SilentlyContinue
            }
            catch { }
        }
        
        if ($versionModuleExists) {
            try {
                "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] Loading ProfileVersion module" | Out-File -FilePath $profileLogFile -Append -Encoding UTF8 -ErrorAction SilentlyContinue
            }
            catch { }
            
            try {
                Import-Module $profileVersionModule -ErrorAction SilentlyContinue -DisableNameChecking
                if (Get-Command Initialize-ProfileVersion -ErrorAction SilentlyContinue) {
                    try {
                        "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] Calling Initialize-ProfileVersion" | Out-File -FilePath $profileLogFile -Append -Encoding UTF8 -ErrorAction SilentlyContinue
                    }
                    catch { }
                    Initialize-ProfileVersion -ProfileDir $profileDir
                    try {
                        "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] Initialize-ProfileVersion completed" | Out-File -FilePath $profileLogFile -Append -Encoding UTF8 -ErrorAction SilentlyContinue
                    }
                    catch { }
                }
                else {
                    try {
                        "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] Initialize-ProfileVersion function not found after module import" | Out-File -FilePath $profileLogFile -Append -Encoding UTF8 -ErrorAction SilentlyContinue
                    }
                    catch { }
                }
            }
            catch {
                try {
                    "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] Failed to load ProfileVersion module: $($_.Exception.Message)" | Out-File -FilePath $profileLogFile -Append -Encoding UTF8 -ErrorAction SilentlyContinue
                }
                catch { }
                if ($env:PS_PROFILE_DEBUG) {
                    Write-Warning "Failed to load ProfileVersion module: $($_.Exception.Message)"
                }
            }
        }
        else {
            try {
                "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] ProfileVersion module not found at: $profileVersionModule" | Out-File -FilePath $profileLogFile -Append -Encoding UTF8 -ErrorAction SilentlyContinue
            }
            catch { }
        }
    }
}
catch {
    try {
        "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] Error in profile version section: $($_.Exception.Message)" | Out-File -FilePath $profileLogFile -Append -Encoding UTF8 -ErrorAction SilentlyContinue
    }
    catch { }
}

# Skip interactive initialization for non-interactive hosts (e.g., automation scripts)
# Non-interactive hosts don't have RawUI, so we exit early to avoid errors
try {
    try {
        "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] Before host check" | Out-File -FilePath $profileLogFile -Append -Encoding UTF8 -ErrorAction SilentlyContinue
    }
    catch { }
    
    if (-not $Host -or -not $Host.UI -or -not $Host.UI.RawUI) {
        $hostInfo = if ($Host) { $Host.Name } else { "null" }
        $uiInfo = if ($Host -and $Host.UI) { "present" } else { "null" }
        $rawUiInfo = if ($Host -and $Host.UI -and $Host.UI.RawUI) { "present" } else { "null" }
        $msg = "[profile] Early exit: Non-interactive host detected (Host: $hostInfo, UI: $uiInfo, RawUI: $rawUiInfo)"
        if ($debugLevel -ge 1) {
            try {
                Write-Host $msg -ForegroundColor Yellow
            }
            catch {
                # Fallback to Write-Output if Write-Host fails (non-interactive host)
                Write-Output $msg
            }
        }
        try {
            "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] $msg" | Out-File -FilePath $profileLogFile -Append -Encoding UTF8 -ErrorAction SilentlyContinue
        }
        catch { }
        return
    }

    # Debug: Confirm we passed the host check
    try {
        "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] Host check passed" | Out-File -FilePath $profileLogFile -Append -Encoding UTF8 -ErrorAction SilentlyContinue
    }
    catch { }
    
    if ($debugLevel -ge 2) {
        try {
            Write-Host "[profile] Host check passed - continuing with profile loading" -ForegroundColor Green
        }
        catch {
            # Fallback to Write-Output if Write-Host fails (non-interactive host)
            Write-Output "[profile] Host check passed - continuing with profile loading"
        }
    }
}
catch {
    try {
        "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] Error in host check: $($_.Exception.Message)" | Out-File -FilePath $profileLogFile -Append -Encoding UTF8 -ErrorAction SilentlyContinue
    }
    catch { }
}

# PSReadLine is loaded lazily by profile.d/psreadline.ps1 to improve startup performance.
# Call Enable-PSReadLine to load PSReadLine with enhanced configuration.

# ===============================================
# COMMON ENUMS - MUST BE LOADED FIRST
# ===============================================
# Import CommonEnums before any module that uses FileSystemPathType or other enums
# This ensures types are available at parse time for modules like Validation
if (-not $profileDir) {
    $profileDir = Split-Path -Parent $PSCommandPath
}
$commonEnumsModule = Join-Path $profileDir 'scripts' 'lib' 'core' 'CommonEnums.psm1'
if ($commonEnumsModule -and -not [string]::IsNullOrWhiteSpace($commonEnumsModule) -and (Test-Path -LiteralPath $commonEnumsModule)) {
    try {
        Import-Module $commonEnumsModule -DisableNameChecking -Force -Global -ErrorAction SilentlyContinue
    }
    catch {
        if ($env:PS_PROFILE_DEBUG) {
            $debugLevel = 0
            if ([int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel) -and $debugLevel -ge 1) {
                Write-Warning "Failed to load CommonEnums module: $($_.Exception.Message). Some modules may fail to load."
            }
        }
    }
}

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
            $null = Initialize-ProfileScoop -ProfileDir $profileDir
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
# NOTE: .ENV FILES ALREADY LOADED EARLIER
# ===============================================
# .env files are now loaded at the very beginning (before debug checks)
# to ensure PS_PROFILE_DEBUG from .env is available for all debug output
# This section is kept for reference but .env loading happens earlier

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
        [CmdletBinding()]
        param(
            [Parameter(Mandatory = $false)]
            [AllowEmptyString()]
            [AllowNull()]
            [string]$Value
        )
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
    try {
        "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] Before fragment loading section" | Out-File -FilePath $profileLogFile -Append -Encoding UTF8 -ErrorAction SilentlyContinue
    }
    catch { }
    
    $profileFragmentLoaderModule = Join-Path $profileDir 'scripts' 'lib' 'profile' 'ProfileFragmentLoader.psm1'
    
    try {
        "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] Fragment loader module path: $profileFragmentLoaderModule" | Out-File -FilePath $profileLogFile -Append -Encoding UTF8 -ErrorAction SilentlyContinue
    }
    catch { }
    
    if ($profileFragmentLoaderModule -and -not [string]::IsNullOrWhiteSpace($profileFragmentLoaderModule) -and (Test-Path -LiteralPath $profileFragmentLoaderModule)) {
        try {
            try {
                "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] Fragment loader module exists, importing..." | Out-File -FilePath $profileLogFile -Append -Encoding UTF8 -ErrorAction SilentlyContinue
            }
            catch { }
            
            $importError = $null
            Import-Module $profileFragmentLoaderModule -ErrorAction Stop -DisableNameChecking -ErrorVariable importError
            
            try {
                "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] Fragment loader module imported successfully" | Out-File -FilePath $profileLogFile -Append -Encoding UTF8 -ErrorAction SilentlyContinue
            }
            catch { }
            $initFunc = Get-Command Initialize-FragmentLoading -ErrorAction SilentlyContinue
            $debugLevel = 0
            if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel) -and $debugLevel -ge 3) {
                if ($initFunc) {
                    Write-Host "[profile] Initialize-FragmentLoading function found, calling..." -ForegroundColor DarkGray
                }
                else {
                    Write-Host "[profile] ✗ Initialize-FragmentLoading function NOT found after module import" -ForegroundColor Red
                    $module = Get-Module ProfileFragmentLoader -ErrorAction SilentlyContinue
                    if ($module) {
                        Write-Host "[profile] Module loaded: $($module.Name), ExportedFunctions: $($module.ExportedFunctions.Keys -join ', ')" -ForegroundColor DarkGray
                    }
                    else {
                        Write-Host "[profile] Module ProfileFragmentLoader not found in Get-Module" -ForegroundColor DarkGray
                    }
                }
            }
            if ($initFunc) {
                try {
                    "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] Calling Initialize-FragmentLoading with $($fragmentsToLoad.Count) fragments" | Out-File -FilePath $profileLogFile -Append -Encoding UTF8 -ErrorAction SilentlyContinue
                }
                catch { }
                
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
                
                try {
                    "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] Initialize-FragmentLoading completed" | Out-File -FilePath $profileLogFile -Append -Encoding UTF8 -ErrorAction SilentlyContinue
                }
                catch { }
            }
            else {
                try {
                    "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] Initialize-FragmentLoading function not found" | Out-File -FilePath $profileLogFile -Append -Encoding UTF8 -ErrorAction SilentlyContinue
                }
                catch { }
            }
        }
        catch {
            if ($env:PS_PROFILE_DEBUG) {
                $debugLevel = 0
                [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel) | Out-Null
                $posMsg = $null
                try {
                    if ($_.InvocationInfo -and $_.InvocationInfo.PositionMessage) {
                        $posMsg = $_.InvocationInfo.PositionMessage.Trim()
                    }
                }
                catch {
                    $posMsg = $null
                }

                if ($debugLevel -ge 3) {
                    Write-Host "[profile] ✗ Failed to load ProfileFragmentLoader module: $($_.Exception.Message)" -ForegroundColor Red
                    if ($posMsg) {
                        Write-Host "[profile] Position: $posMsg" -ForegroundColor DarkGray
                    }
                    Write-Host "[profile] Exception type: $($_.Exception.GetType().FullName)" -ForegroundColor DarkGray
                    if ($_.ScriptStackTrace) {
                        Write-Host "[profile] Stack trace: $($_.ScriptStackTrace)" -ForegroundColor DarkGray
                    }
                }
                elseif ($posMsg) {
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
                    # Debug level behavior: Level 1 = batched, Level 2+ = individual messages
                    $debugLevel = 0
                    [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel) | Out-Null
                    $showIndividualFragments = $debugLevel -ge 2
                    
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

                # Set fragment context for command registry
                $originalFragmentContext = $null
                if (Get-Variable -Name 'CurrentFragmentContext' -Scope Global -ErrorAction SilentlyContinue) {
                    $originalFragmentContext = $global:CurrentFragmentContext
                }
                $global:CurrentFragmentContext = $fragmentBaseName

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
                    # Restore or clear fragment context
                    if ($null -ne $originalFragmentContext) {
                        $global:CurrentFragmentContext = $originalFragmentContext
                    }
                    else {
                        Remove-Variable -Name 'CurrentFragmentContext' -Scope Global -ErrorAction SilentlyContinue
                    }
                }
            }
            
            # Show remaining fragments if batching
            # Debug level behavior: Level 1 = batched, Level 2+ = individual messages (already shown)
            if ($env:PS_PROFILE_DEBUG -and $fallbackLoadedFragments.Count -gt 0) {
                $debugLevel = 0
                [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel) | Out-Null
                $showIndividualFragments = $debugLevel -ge 2
                
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
                # Debug level behavior: Level 1 = batched, Level 2+ = individual messages
                $debugLevel = 0
                [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel) | Out-Null
                $showIndividualFragments = $debugLevel -ge 2
                
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

            # Set fragment context for command registry
            $originalFragmentContext = $null
            if (Get-Variable -Name 'CurrentFragmentContext' -Scope Global -ErrorAction SilentlyContinue) {
                $originalFragmentContext = $global:CurrentFragmentContext
            }
            $global:CurrentFragmentContext = $fragmentBaseName

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
                # Restore or clear fragment context
                if ($null -ne $originalFragmentContext) {
                    $global:CurrentFragmentContext = $originalFragmentContext
                }
                else {
                    Remove-Variable -Name 'CurrentFragmentContext' -Scope Global -ErrorAction SilentlyContinue
                }
            }
        }
        
        # Show remaining fragments if batching
        # Debug level behavior: Level 1 = batched, Level 2+ = individual messages (already shown)
        if ($env:PS_PROFILE_DEBUG -and $fallbackLoadedFragments2.Count -gt 0) {
            $debugLevel = 0
            [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel) | Out-Null
            $showIndividualFragments = $debugLevel -ge 2
            
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
        # Parse debug level once at function/script start
        $debugLevel = 0
        if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel)) {
            # Debug is enabled, $debugLevel contains the numeric level (1-3)
        }
        
        # Level 2: Verbose debug - module loading details
        if ($debugLevel -ge 2) {
            Write-Host "  [profile.prompt] Loading ProfilePrompt module..." -ForegroundColor DarkGray
        }
        
        Import-Module $profilePromptModule -ErrorAction Stop -DisableNameChecking
        
        if (Get-Command Initialize-ProfilePrompt -ErrorAction SilentlyContinue) {
            # Level 2: Verbose debug - initialization details
            if ($debugLevel -ge 2) {
                Write-Host "  [profile.prompt] Calling Initialize-ProfilePrompt..." -ForegroundColor DarkGray
            }
            Initialize-ProfilePrompt
        }
        else {
            # Level 1: Basic debug - function not found warning
            if ($debugLevel -ge 1) {
                Write-Warning "[profile.prompt] Initialize-ProfilePrompt function not found after importing module"
            }
        }
    }
    catch {
        $errorMsg = "Failed to load ProfilePrompt module: $($_.Exception.Message)"
        
        # Always use structured error handling if available
        if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
            Write-StructuredError -ErrorRecord $_ -OperationName 'profile.load-prompt-module' -Context @{
                module_path = $profilePromptModule
            }
        }
        
        # Parse debug level for error display
        $debugLevel = 0
        if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel)) {
            # Level 1: Basic error display (errors should be prominently displayed)
            if ($debugLevel -ge 1) {
                Write-Host "[profile.prompt] $errorMsg" -ForegroundColor Red
            }
            # Level 3: Detailed error information including stack trace
            if ($debugLevel -ge 3) {
                if ($_.ScriptStackTrace) {
                    Write-Host "  [profile.prompt] Stack trace: $($_.ScriptStackTrace)" -ForegroundColor DarkGray
                }
                Write-Host "  [profile.prompt] Exception type: $($_.Exception.GetType().FullName)" -ForegroundColor DarkGray
            }
        }
        else {
            # Always show errors even if debug is off
            Write-Warning $errorMsg
        }
    }
}
else {
    # Parse debug level for module not found message
    $debugLevel = 0
    if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel)) {
        # Level 2: Verbose debug - module path diagnostics
        if ($debugLevel -ge 2) {
            Write-Host "  [profile.prompt] ProfilePrompt module not found at: $profilePromptModule" -ForegroundColor DarkGray
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
