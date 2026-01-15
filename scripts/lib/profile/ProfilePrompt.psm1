# ===============================================
# ProfilePrompt.psm1
# Prompt system initialization
# ===============================================

<#
.SYNOPSIS
    Initializes the prompt system (Starship or fallback).
.DESCRIPTION
    Initializes prompt system after all fragments load to ensure prompt configuration functions are available.
    Supports Starship prompt with performance insights integration.
#>
function Initialize-ProfilePrompt {
    [CmdletBinding()]
    param()

    try {
        $debugLevel = 0
        if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel)) {
            # Level 1: Basic initialization start
            if ($debugLevel -ge 1) {
                Write-Verbose "[profile.prompt.initialize] Starting prompt initialization..."
            }
            # Level 2: Detailed initialization steps
            if ($debugLevel -ge 2) {
                Write-Verbose "[profile.prompt.initialize] Checking for Initialize-Starship function..."
            }
        }
        
        # Check if starship command is available
        $starshipCommandAvailable = $false
        if (Get-Command Test-CachedCommand -ErrorAction SilentlyContinue) {
            $starshipCommandAvailable = Test-CachedCommand 'starship'
        }
        elseif ($null -ne (Get-Command starship -ErrorAction SilentlyContinue)) {
            $starshipCommandAvailable = $true
        }
        
        $debugLevel = 0
        if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel) -and $debugLevel -ge 2) {
            Write-Verbose "[profile.prompt.initialize] Starship command available: $starshipCommandAvailable"
        }
        
        $initializeStarshipExists = Get-Command Initialize-Starship -ErrorAction SilentlyContinue
        if ($initializeStarshipExists) {
            $debugLevel = 0
            if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel) -and $debugLevel -ge 2) {
                Write-Verbose "[profile.prompt.initialize] Initialize-Starship function found: $($initializeStarshipExists.Source)"
                $fragmentLoaded = $false
                if (Get-Command Test-FragmentLoaded -ErrorAction SilentlyContinue) {
                    $fragmentLoaded = Test-FragmentLoaded -FragmentName 'starship'
                    Write-Verbose "[profile.prompt.initialize] Starship fragment loaded normally: $fragmentLoaded"
                }
            }
            
            if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel) -and $debugLevel -ge 2) {
                Write-Verbose "[profile.prompt.initialize] Initialize-Starship function found, calling it..."
            }
            try {
                Initialize-Starship
                
                # Verify Starship actually initialized by checking for prompt function
                $promptFunction = Get-Command prompt -CommandType Function -ErrorAction SilentlyContinue
                if ($promptFunction) {
                    $debugLevel = 0
                    if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel) -and $debugLevel -ge 2) {
                        Write-Verbose "[profile.prompt.initialize] Initialize-Starship completed - prompt function: $($promptFunction.Name)"
                    }
                    
                    if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel) -and $debugLevel -ge 3) {
                        Write-Host "  [profile.prompt.initialize] Prompt function source: $($promptFunction.Source)" -ForegroundColor DarkGray
                    }
                }
                else {
                    $debugLevel = 0
                    if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel) -and $debugLevel -ge 1) {
                        Write-Verbose "[profile.prompt.initialize] Initialize-Starship completed but no prompt function found - Starship may not have initialized"
                    }
                }
            }
            catch {
                $errorMessage = "Failed to initialize Starship: $($_.Exception.Message)"
                $debugLevel = 0
                if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel)) {
                    if ($debugLevel -ge 1) {
                        if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                            Write-StructuredError -ErrorRecord $_ -OperationName 'profile.prompt.initialize-starship' -Context @{
                                prompt_type          = 'starship'
                                initialization_stage = 'starship-initialization'
                            }
                        }
                        elseif (Get-Command Write-ProfileError -ErrorAction SilentlyContinue) {
                            Write-ProfileError -ErrorRecord $_ -Context "Prompt initialization (Initialize-Starship)" -Category 'Profile'
                        }
                        else {
                            Write-Error "[profile.prompt.initialize-starship] $errorMessage"
                        }
                    }
                    # Level 3: Log detailed error information
                    if ($debugLevel -ge 3) {
                        Write-Host "  [profile.prompt.initialize-starship] Initialization error details - Exception: $($_.Exception.GetType().FullName), Message: $($_.Exception.Message), Stack: $($_.ScriptStackTrace)" -ForegroundColor DarkGray
                    }
                }
                else {
                    # Always log critical errors even if debug is off
                    if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                        Write-StructuredError -ErrorRecord $_ -OperationName 'profile.prompt.initialize-starship' -Context @{
                            # Technical context
                            prompt_type                = 'starship'
                            initialization_stage       = 'starship-initialization'
                            starship_command_available = $starshipCommandAvailable
                            initialize_starship_exists = ($initializeStarshipExists -ne $null)
                            # Error context
                            ErrorType                  = $_.Exception.GetType().FullName
                            # Invocation context
                            FunctionName               = 'Initialize-ProfilePrompt'
                        }
                    }
                    else {
                        Write-Error "[profile.prompt.initialize-starship] $errorMessage"
                    }
                }
                return
            }

            # Verify prompt function was created successfully
            if (Get-Command prompt -CommandType Function -ErrorAction SilentlyContinue) {
                $debugLevel = 0
                if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel) -and $debugLevel -ge 2) {
                    Write-Verbose "[profile.prompt.initialize] Prompt function verified and active"
                }
                
                # Re-wrap prompt with performance insights if available
                # This ensures performance timing works with Starship prompt
                if (Get-Command Update-PerformanceInsightsPrompt -ErrorAction SilentlyContinue) {
                    try {
                        Update-PerformanceInsightsPrompt
                        $debugLevel = 0
                        if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel) -and $debugLevel -ge 3) {
                            Write-Host "  [profile.prompt.initialize] Performance insights prompt wrapper updated" -ForegroundColor DarkGray
                        }
                    }
                    catch {
                        $errorMessage = "Failed to update performance insights prompt: $($_.Exception.Message)"
                        $debugLevel = 0
                        if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel)) {
                            if ($debugLevel -ge 1) {
                                if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                                    Write-StructuredError -ErrorRecord $_ -OperationName 'profile.prompt.update-performance-insights' -Context @{
                                        prompt_type          = 'starship'
                                        initialization_stage = 'performance-insights-update'
                                    }
                                }
                                elseif (Get-Command Write-ProfileError -ErrorAction SilentlyContinue) {
                                    Write-ProfileError -ErrorRecord $_ -Context "Prompt initialization (Update-PerformanceInsightsPrompt)" -Category 'Profile'
                                }
                                else {
                                    Write-Error "[profile.prompt.update-performance-insights] $errorMessage"
                                }
                            }
                            # Level 3: Log detailed error information
                            if ($debugLevel -ge 3) {
                                Write-Host "  [profile.prompt.update-performance-insights] Update error details - Exception: $($_.Exception.GetType().FullName), Message: $($_.Exception.Message), Stack: $($_.ScriptStackTrace)" -ForegroundColor DarkGray
                            }
                        }
                        else {
                            # Always log critical errors even if debug is off
                            if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                                Write-StructuredError -ErrorRecord $_ -OperationName 'profile.prompt.update-performance-insights' -Context @{
                                    # Technical context
                                    prompt_type          = 'starship'
                                    initialization_stage = 'performance-insights-update'
                                    # Error context
                                    ErrorType            = $_.Exception.GetType().FullName
                                    # Invocation context
                                    FunctionName         = 'Initialize-ProfilePrompt'
                                }
                            }
                            else {
                                Write-Error "[profile.prompt.update-performance-insights] $errorMessage"
                            }
                        }
                    }
                }
            }
            else {
                $errorMessage = "Prompt function not found after Starship initialization"
                $debugLevel = 0
                if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel)) {
                    if ($debugLevel -ge 1) {
                        if (Get-Command Write-StructuredWarning -ErrorAction SilentlyContinue) {
                            Write-StructuredWarning -Message $errorMessage -OperationName 'profile.prompt.verify' -Context @{
                                prompt_type          = 'starship'
                                initialization_stage = 'prompt-verification'
                                starship_initialized = $true
                            } -Code 'PROMPT_NOT_FOUND'
                        }
                        elseif (Get-Command Write-ProfileError -ErrorAction SilentlyContinue) {
                            $errorRecord = [System.Management.Automation.ErrorRecord]::new(
                                [System.Exception]::new($errorMessage),
                                'PromptNotFound',
                                [System.Management.Automation.ErrorCategory]::InvalidOperation,
                                $null
                            )
                            Write-ProfileError -ErrorRecord $errorRecord -Context "Prompt initialization (prompt verification)" -Category 'Profile'
                        }
                        else {
                            Write-Warning "[profile.prompt.verify] $errorMessage"
                        }
                    }
                    # Level 3: Log detailed verification information
                    if ($debugLevel -ge 3) {
                        Write-Host "  [profile.prompt.verify] Verification details - PromptFunctionFound: $false, StarshipInitialized: $true, InitializeStarshipExists: $($initializeStarshipExists -ne $null)" -ForegroundColor DarkGray
                    }
                }
                else {
                    # Always log warnings even if debug is off
                    if (Get-Command Write-StructuredWarning -ErrorAction SilentlyContinue) {
                        Write-StructuredWarning -Message $errorMessage -OperationName 'profile.prompt.verify' -Context @{
                            # Technical context
                            prompt_type                = 'starship'
                            initialization_stage       = 'prompt-verification'
                            starship_initialized       = $true
                            prompt_function_found      = $false
                            initialize_starship_exists = ($initializeStarshipExists -ne $null)
                            # Invocation context
                            FunctionName               = 'Initialize-ProfilePrompt'
                        } -Code 'PROMPT_NOT_FOUND'
                    }
                    else {
                        Write-Warning "[profile.prompt.verify] $errorMessage"
                    }
                }
            }
        }
        else {
            $warningMessage = "Starship not available (Initialize-Starship function not found) - using fallback prompt"
            
            # Additional diagnostics
            $diagnostics = @()
            $diagnostics += "  - Starship command available: $starshipCommandAvailable"
            
            # Check if starship fragment file exists
            # ProfilePrompt.psm1 is at scripts/lib/profile/ProfilePrompt.psm1
            # We need to go up 3 levels to get to the repo root
            $profileDir = $null
            if (Get-Command Get-RepoRoot -ErrorAction SilentlyContinue) {
                $profileDir = Get-RepoRoot -ScriptPath $PSScriptRoot -ErrorAction SilentlyContinue
            }
            
            # If Get-RepoRoot didn't work or isn't available, calculate from PSScriptRoot
            if (-not $profileDir -and $PSScriptRoot) {
                # Go up 3 levels: scripts/lib/profile -> scripts/lib -> scripts -> root
                $currentPath = $PSScriptRoot
                for ($i = 0; $i -lt 3; $i++) {
                    $parentPath = Split-Path -Parent $currentPath
                    if ([string]::IsNullOrWhiteSpace($parentPath) -or $parentPath -eq $currentPath) {
                        break
                    }
                    $currentPath = $parentPath
                }
                $profileDir = $currentPath
            }
            
            # Fallback: try to find profile.d directory by walking up from PSScriptRoot
            if (-not $profileDir -or -not (Test-Path -LiteralPath (Join-Path $profileDir 'profile.d') -ErrorAction SilentlyContinue)) {
                $searchPath = $PSScriptRoot
                while ($searchPath -and -not [string]::IsNullOrWhiteSpace($searchPath)) {
                    $testProfileD = Join-Path $searchPath 'profile.d'
                    if (Test-Path -LiteralPath $testProfileD -ErrorAction SilentlyContinue) {
                        $profileDir = $searchPath
                        break
                    }
                    $parent = Split-Path -Parent $searchPath
                    if ($parent -eq $searchPath) { break }
                    $searchPath = $parent
                }
            }
            $starshipFragmentPath = if ($profileDir) {
                Join-Path $profileDir 'profile.d' 'starship.ps1'
            }
            else {
                $null
            }
            $starshipFragmentExists = if ($starshipFragmentPath) {
                Test-Path -LiteralPath $starshipFragmentPath -ErrorAction SilentlyContinue
            }
            else {
                $false
            }
            $diagnostics += "  - Starship fragment file exists: $starshipFragmentExists"
            
            # Check if fragment was loaded (if Test-FragmentLoaded is available)
            $fragmentLoaded = $false
            if (Get-Command Test-FragmentLoaded -ErrorAction SilentlyContinue) {
                $fragmentLoaded = Test-FragmentLoaded -FragmentName 'starship'
                $diagnostics += "  - Starship fragment loaded: $fragmentLoaded"
                if (-not $fragmentLoaded) {
                    $diagnostics += "  - Fragment not loaded - this may be why Initialize-Starship is not found"
                }
            }
            else {
                $diagnostics += "  - Test-FragmentLoaded not available - cannot check fragment load status"
            }
            
            $diagnostics += "  - Initialize-Starship function: Not found"
            $diagnostics += "  - This may indicate the starship fragment did not load properly or loaded after Initialize-ProfilePrompt"
            
            # Try to manually load the fragment if it wasn't loaded during initialization
            # This ensures Starship works even if the fragment failed to load during profile init
            if ($starshipFragmentExists -and -not (Get-Command Initialize-Starship -ErrorAction SilentlyContinue)) {
                $debugLevel = 0
                if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel) -and $debugLevel -ge 2) {
                    Write-Verbose "[profile.prompt.initialize] Attempting to manually load starship fragment..."
                }
                try {
                    . $starshipFragmentPath
                    $functionNowExists = (Get-Command Initialize-Starship -ErrorAction SilentlyContinue) -ne $null
                    if ($functionNowExists) {
                        $diagnostics += "  - Manual load succeeded - function now available"
                        $debugLevel = 0
                        if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel) -and $debugLevel -ge 2) {
                            Write-Verbose "[profile.prompt.initialize] Manual load succeeded - Initialize-Starship function is now available"
                        }
                        # Try to initialize it now
                        try {
                            Initialize-Starship
                            $debugLevel = 0
                            if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel) -and $debugLevel -ge 2) {
                                Write-Verbose "[profile.prompt.initialize] Starship initialized successfully after manual load"
                            }
                            # Success - Starship is now working, no need to show warning or continue with diagnostics
                            return
                        }
                        catch {
                            $initError = "Starship initialization failed after manual load: $($_.Exception.Message)"
                            $debugLevel = 0
                            if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel) -and $debugLevel -ge 1) {
                                Write-Verbose "[profile.prompt.initialize] $initError"
                            }
                            $diagnostics += "  - $initError"
                            if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                                Write-StructuredError -ErrorRecord $_ -OperationName 'profile.prompt.initialize-starship' -Context @{
                                    prompt_type          = 'starship'
                                    initialization_stage = 'starship-initialization-after-manual-load'
                                }
                            }
                            elseif (Get-Command Write-ProfileError -ErrorAction SilentlyContinue) {
                                Write-ProfileError -ErrorRecord $_ -Context "Prompt initialization (Initialize-Starship after manual load)" -Category 'Profile'
                            }
                            else {
                                $debugLevel = 0
                                if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel)) {
                                    if ($debugLevel -ge 1) {
                                        if (Get-Command Write-StructuredWarning -ErrorAction SilentlyContinue) {
                                            Write-StructuredWarning -Message $initError -OperationName 'profile.prompt.initialize' -Context @{
                                                PromptType = 'starship'
                                                Stage      = 'manual-initialization'
                                            }
                                        }
                                        else {
                                            Write-Warning "[profile.prompt.initialize] $initError"
                                        }
                                    }
                                    # Level 3: Log detailed initialization error information
                                    if ($debugLevel -ge 3) {
                                        Write-Host "  [profile.prompt.initialize] Manual initialization error details - Error: $initError" -ForegroundColor DarkGray
                                    }
                                }
                            }
                        }
                    }
                    else {
                        $diagnostics += "  - Manual load completed but function still not found"
                        $debugLevel = 0
                        if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel) -and $debugLevel -ge 2) {
                            Write-Verbose "[profile.prompt.initialize] Manual load completed but Initialize-Starship function still not found"
                        }
                    }
                }
                catch {
                    $loadError = "Manual load failed: $($_.Exception.Message)"
                    $diagnostics += "  - $loadError"
                    $debugLevel = 0
                    if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel)) {
                        if ($debugLevel -ge 1) {
                            if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                                Write-StructuredError -ErrorRecord $_ -OperationName 'profile.prompt.load-starship-fragment' -Context @{
                                    prompt_type          = 'fallback'
                                    initialization_stage = 'manual-fragment-load'
                                    FragmentPath         = $starshipFragmentPath
                                }
                            }
                            else {
                                Write-Error "[profile.prompt.load-starship-fragment] $loadError"
                            }
                        }
                        # Level 3: Log detailed error information including stack trace
                        if ($debugLevel -ge 3) {
                            Write-Host "  [profile.prompt.load-starship-fragment] Load error details - FragmentPath: $starshipFragmentPath, Exception: $($_.Exception.GetType().FullName), Message: $($_.Exception.Message)" -ForegroundColor DarkGray
                            if ($_.ScriptStackTrace) {
                                Write-Host "  [profile.prompt.load-starship-fragment] Stack trace: $($_.ScriptStackTrace)" -ForegroundColor DarkGray
                            }
                        }
                    }
                    else {
                        # If debug is not enabled, still write error but without structured format
                        if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                            Write-StructuredError -ErrorRecord $_ -OperationName 'profile.prompt.load-starship-fragment' -Context @{
                                prompt_type          = 'fallback'
                                initialization_stage = 'manual-fragment-load'
                                FragmentPath         = $starshipFragmentPath
                            }
                        }
                    }
                }
            }
            
            # Only show warning if manual load didn't succeed (we would have returned early if it did)
            $debugLevel = 0
            if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel) -and $debugLevel -ge 1) {
                Write-Verbose "[profile.prompt.initialize] $warningMessage"
            }
            
            $debugLevel = 0
            if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel) -and $debugLevel -ge 2) {
                foreach ($diag in $diagnostics) {
                    $color = if ($diag -match 'available: True|exists: True|loaded: True') { 'Green' } 
                    elseif ($diag -match 'available: False|exists: False|loaded: False|Not found') { 'Yellow' }
                    else { 'Gray' }
                    Write-Host "[profile.prompt.initialize] $diag" -ForegroundColor $color
                }
            }
            
            $debugLevel = 0
            if (-not ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel) -and $debugLevel -ge 1)) {
                # Only show warning in non-debug mode if manual load wasn't attempted or failed
                Write-Warning "[profile.prompt.initialize] $warningMessage"
            }
            
            if (Get-Command Write-StructuredWarning -ErrorAction SilentlyContinue) {
                Write-StructuredWarning -Message $warningMessage -OperationName 'profile.prompt.initialize' -Context @{
                    prompt_type               = 'fallback'
                    initialization_stage      = 'starship-check'
                    starship_available        = $starshipCommandAvailable
                    starship_fragment_exists  = $starshipFragmentExists
                    starship_fragment_loaded  = $fragmentLoaded
                    initialize_function_found = $false
                } -Code 'STARSHIP_NOT_AVAILABLE'
            }
        }
    }
    catch {
        $errorMessage = "Prompt initialization failed: $($_.Exception.Message)"
        $debugLevel = 0
        if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel)) {
            if ($debugLevel -ge 1) {
                if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                    Write-StructuredError -ErrorRecord $_ -OperationName 'profile.prompt.initialize' -Context @{
                        PromptType = 'unknown'
                        Stage      = 'initialization'
                    }
                }
                else {
                    Write-Error "[profile.prompt.initialize] $errorMessage"
                }
            }
            # Level 3: Log detailed error information
            if ($debugLevel -ge 3) {
                Write-Host "  [profile.prompt.initialize] Initialization error details - Exception: $($_.Exception.GetType().FullName), Message: $($_.Exception.Message), Stack: $($_.ScriptStackTrace)" -ForegroundColor DarkGray
            }
        }
        else {
            # Always log critical errors even if debug is off
            if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                Write-StructuredError -ErrorRecord $_ -OperationName 'profile.prompt.initialize' -Context @{
                    initialization_stage = 'general-initialization'
                }
            }
            elseif (Get-Command Write-ProfileError -ErrorAction SilentlyContinue) {
                Write-ProfileError -ErrorRecord $_ -Context "Prompt initialization" -Category 'Profile'
            }
        }
    }
}

Export-ModuleMember -Function 'Initialize-ProfilePrompt'
