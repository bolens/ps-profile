<#
# Tier: essential
# Dependencies: bootstrap, env

# starship.ps1

Simple initialization of the Starship prompt for PowerShell.

Behavior:
 - If the `starship` command is available, this fragment will call
   `starship init powershell` to set up the prompt using the starship.toml config.
 - If starship is not available, provides a smart fallback prompt.
 - The fragment is idempotent: it will only initialize once per session.
 - It is quiet when dot-sourced (returns no output) so the interactive
   shell startup remains clean.

Notes:
 - Now uses standard starship initialization with starship.toml configuration.
 - Much simpler than the previous complex VS Code handling logic.
#>

try {
    # Parse debug level once at fragment start
    $debugLevel = 0
    if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel)) {
        # Debug is enabled, $debugLevel contains the numeric level (1-3)
    }
    
    # Diagnostic: Confirm fragment is being loaded (this should appear during normal fragment loading)
    # If this only appears during manual load, the fragment isn't being loaded normally
    # Level 2: Verbose debug - fragment loading details
    if ($debugLevel -ge 2) {
        $callStack = Get-PSCallStack
        $isManualLoad = $callStack | Where-Object { $_.ScriptName -like '*ProfilePrompt*' }
        if ($isManualLoad) {
            Write-Host "  [fragment.starship] Loading starship fragment (MANUAL LOAD)..." -ForegroundColor DarkGray
        }
        else {
            Write-Host "  [fragment.starship] Loading starship fragment (NORMAL LOAD)..." -ForegroundColor DarkGray
        }
    }
    
    # Remove any existing Initialize-Starship function to ensure we have the latest version
    # This handles cases where the fragment might be re-sourced during development
    Remove-Item Function:Initialize-Starship -Force -ErrorAction SilentlyContinue
    Remove-Item Function:global:Initialize-Starship -Force -ErrorAction SilentlyContinue
    
    # Ensure Test-CachedCommand is available (from bootstrap.ps1)
    # Bootstrap loads first, so this should always be available, but we check for safety
    if (-not (Get-Command Test-CachedCommand -ErrorAction SilentlyContinue)) {
        if (Get-Command Write-StructuredWarning -ErrorAction SilentlyContinue) {
            Write-StructuredWarning -Message "Test-CachedCommand not available - Starship fragment may not initialize correctly" -OperationName 'fragment.starship.bootstrap-check' -Context @{
                fragment_name   = 'starship'
                missing_command = 'Test-CachedCommand'
            } -Code 'MISSING_DEPENDENCY'
        }
        else {
            Write-Warning "Test-CachedCommand not available - Starship fragment may not initialize correctly"
        }
    }
    
    # Load Starship helper modules
    # Use standardized module loading if available, otherwise fall back to manual loading
    $modulesLoaded = $false
    if (Get-Command Import-FragmentModules -ErrorAction SilentlyContinue) {
        try {
            $modules = @(
                @{ ModulePath = @('starship', 'StarshipHelpers.ps1'); Context = 'Fragment: starship (StarshipHelpers.ps1)' },
                @{ ModulePath = @('starship', 'StarshipPrompt.ps1'); Context = 'Fragment: starship (StarshipPrompt.ps1)' },
                @{ ModulePath = @('starship', 'StarshipModule.ps1'); Context = 'Fragment: starship (StarshipModule.ps1)' },
                @{ ModulePath = @('starship', 'StarshipInit.ps1'); Context = 'Fragment: starship (StarshipInit.ps1)' },
                @{ ModulePath = @('starship', 'StarshipVSCode.ps1'); Context = 'Fragment: starship (StarshipVSCode.ps1)' },
                @{ ModulePath = @('starship', 'SmartPrompt.ps1'); Context = 'Fragment: starship (SmartPrompt.ps1)' }
            )
            
            $result = Import-FragmentModules -FragmentRoot $PSScriptRoot -Modules $modules
            $modulesLoaded = $result.SuccessCount -gt 0
            
            if ($env:PS_PROFILE_DEBUG -and $result.FailureCount -gt 0) {
                Write-Verbose "Loaded $($result.SuccessCount) starship modules (failed: $($result.FailureCount))"
            }
        }
        catch {
            if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                Write-StructuredError -ErrorRecord $_ -OperationName 'fragment.starship.module-load' -Context @{
                    fragment_name  = 'starship'
                    loading_method = 'Import-FragmentModules'
                }
            }
            elseif ($env:PS_PROFILE_DEBUG) {
                Write-Warning "Failed to load starship modules: $($_.Exception.Message)"
            }
        }
    }
    else {
        # Fallback: manual loading for environments where Import-FragmentModules is not yet available
        $starshipModulesDir = Join-Path $PSScriptRoot 'starship'
        
        if ($starshipModulesDir -and -not [string]::IsNullOrWhiteSpace($starshipModulesDir) -and (Test-Path -LiteralPath $starshipModulesDir)) {
            $moduleFiles = @(
                'StarshipHelpers.ps1',
                'StarshipPrompt.ps1',
                'StarshipModule.ps1',
                'StarshipInit.ps1',
                'StarshipVSCode.ps1',
                'SmartPrompt.ps1'
            )
            
            foreach ($moduleFile in $moduleFiles) {
                $modulePath = Join-Path $starshipModulesDir $moduleFile
                if ($modulePath -and -not [string]::IsNullOrWhiteSpace($modulePath) -and (Test-Path -LiteralPath $modulePath)) {
                    try {
                        . $modulePath
                        $modulesLoaded = $true
                    }
                    catch {
                        if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                            Write-StructuredError -ErrorRecord $_ -OperationName 'fragment.starship.module-load-manual' -Context @{
                                fragment_name  = 'starship'
                                module_file    = $moduleFile
                                loading_method = 'manual'
                            }
                        }
                        elseif ($env:PS_PROFILE_DEBUG) {
                            Write-Warning "Failed to load $moduleFile : $($_.Exception.Message)"
                        }
                    }
                }
            }
        }
    }
    
    # ================================================
    # MAIN INITIALIZATION FUNCTION
    # ================================================
    # Always create the function, even if module loading failed
    # The function will handle missing dependencies gracefully
    
    <#
    .SYNOPSIS
        Initializes the Starship prompt for PowerShell.
    .DESCRIPTION
        Sets up Starship as the PowerShell prompt if the starship command is available.
        Uses the standard starship initialization which automatically reads starship.toml.
    #>
    # Create Initialize-Starship function - ensure it's in global scope
    # Use Get-Command for more reliable function detection
    # Always create the function, even if module loading had issues
    # Force creation to ensure it's always available, even if previously removed
    try {
        <#
        .SYNOPSIS
            Initializes the Starship prompt for PowerShell.
        .DESCRIPTION
            Sets up Starship as the PowerShell prompt if the starship command is available.
            Uses the standard starship initialization which automatically reads starship.toml.
        #>
        function global:Initialize-Starship {
            try {
                # Check if already initialized
                if (Test-StarshipInitialized) {
                    if ($env:PS_PROFILE_DEBUG) {
                        Write-Host "Starship already initialized, verifying prompt..." -ForegroundColor Cyan
                    }
                
                    # Ensure module stays loaded
                    Initialize-StarshipModule
                
                    # Ensure command path is stored
                    if (-not $global:StarshipCommand) {
                        $starCmd = Get-Command starship -ErrorAction SilentlyContinue
                        if ($starCmd) {
                            $global:StarshipCommand = $starCmd.Source
                        }
                    }
                
                    # Check if prompt needs replacement (module-scoped prompts can break)
                    $currentPrompt = Get-Command prompt -CommandType Function -ErrorAction SilentlyContinue
                    if ($currentPrompt -and (Test-PromptNeedsReplacement -PromptCmd $currentPrompt)) {
                        if ($global:StarshipCommand -and -not [string]::IsNullOrWhiteSpace($global:StarshipCommand) -and (Test-Path -LiteralPath $global:StarshipCommand)) {
                            New-StarshipPromptFunction -StarshipCommandPath $global:StarshipCommand
                            if ($env:PS_PROFILE_DEBUG) {
                                Write-Host "Replaced module prompt with direct starship call" -ForegroundColor Yellow
                            }
                        }
                    }
                
                    if ($env:PS_PROFILE_DEBUG) {
                        Write-Host "Starship prompt verified and active" -ForegroundColor Green
                    }
                    return
                }
            
                # Not initialized - proceed with initialization
                $starCmd = Get-Command starship -ErrorAction SilentlyContinue
                if (-not $starCmd) {
                    if ($env:PS_PROFILE_DEBUG) {
                        Write-Host "Starship not found, using smart prompt" -ForegroundColor Yellow
                    }
                    Initialize-SmartPrompt
                    return
                }
            
                if ($env:PS_PROFILE_DEBUG) {
                    Write-Host "Starship found at: $($starCmd.Source)" -ForegroundColor Green
                }
            
                # Store command path globally
                $global:StarshipCommand = $starCmd.Source
            
                # Execute Starship's initialization script
                $promptFunc = Invoke-StarshipInitScript -StarshipCommandPath $starCmd.Source
            
                # Ensure module stays loaded
                Initialize-StarshipModule
            
                # Replace Starship's module-scoped prompt with direct executable call
                # This avoids issues if the Starship module gets unloaded
                New-StarshipPromptFunction -StarshipCommandPath $starCmd.Source
            
                # Update VS Code if active
                Update-VSCodePrompt
            
                # Re-wrap prompt with performance insights if available
                # This ensures performance timing works with Starship prompt
                if (Get-Command Update-PerformanceInsightsPrompt -ErrorAction SilentlyContinue) {
                    try {
                        Update-PerformanceInsightsPrompt
                        if ($env:PS_PROFILE_DEBUG) {
                            Write-Host "Performance insights prompt wrapper updated after Starship initialization" -ForegroundColor Cyan
                        }
                    }
                    catch {
                        if ($env:PS_PROFILE_DEBUG) {
                            Write-Verbose "Failed to update performance insights prompt: $($_.Exception.Message)"
                        }
                    }
                }
            
                # Mark as initialized
                Set-Variable -Name "StarshipInitialized" -Value $true -Scope Global -Force
                Set-Variable -Name "StarshipActive" -Value $true -Scope Global -Force
                $global:StarshipPromptActive = $true
            
                if ($env:PS_PROFILE_DEBUG) {
                    Write-Host "Starship prompt initialized successfully" -ForegroundColor Green
                }
            }
            catch {
                if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                    Write-StructuredError -ErrorRecord $_ -OperationName 'fragment.starship.initialize' -Context @{
                        fragment_name        = 'starship'
                        initialization_stage = 'starship-initialization'
                    }
                }
                elseif ($env:PS_PROFILE_DEBUG) {
                    Write-Verbose "Initialize-Starship failed: $($_.Exception.Message)"
                }
                Initialize-SmartPrompt
            }
        }
        
        # Verify function was created successfully
        $functionCreated = (Get-Command Initialize-Starship -ErrorAction SilentlyContinue) -ne $null
        if ($functionCreated) {
            # Force the function to be available in global scope explicitly
            # This ensures it's available even if loaded in a parallel runspace
            $func = Get-Command Initialize-Starship -ErrorAction SilentlyContinue
            if ($func -and $func.ModuleName -eq $null) {
                # Function is in global scope, ensure it's accessible
                if ($env:PS_PROFILE_DEBUG) {
                    Write-Host "Initialize-Starship function created successfully in global scope" -ForegroundColor Green
                }
            }
        }
        else {
            if ($env:PS_PROFILE_DEBUG) {
                Write-Warning "Initialize-Starship function was not created successfully"
            }
            if (Get-Command Write-StructuredWarning -ErrorAction SilentlyContinue) {
                Write-StructuredWarning -Message "Initialize-Starship function was not created successfully" -OperationName 'fragment.starship.function-creation' -Context @{
                    fragment_name = 'starship'
                    function_name = 'Initialize-Starship'
                } -Code 'FUNCTION_CREATION_FAILED'
            }
            elseif (Get-Command Write-ProfileError -ErrorAction SilentlyContinue) {
                $errorRecord = [System.Management.Automation.ErrorRecord]::new(
                    [System.Exception]::new("Initialize-Starship function was not created successfully"),
                    'FunctionCreationFailed',
                    [System.Management.Automation.ErrorCategory]::InvalidOperation,
                    $null
                )
                Write-ProfileError -ErrorRecord $errorRecord -Context "Fragment: starship (function creation)" -Category 'Fragment'
            }
        }
    }
    catch {
        # If function creation fails, log but don't prevent fragment from loading
        if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
            Write-StructuredError -ErrorRecord $_ -OperationName 'fragment.starship.function-creation' -Context @{
                fragment_name = 'starship'
                function_name = 'Initialize-Starship'
            }
        }
        elseif (Get-Command Write-ProfileError -ErrorAction SilentlyContinue) {
            Write-ProfileError -ErrorRecord $_ -Context "Fragment: starship (function creation)" -Category 'Fragment'
        }
        elseif ($env:PS_PROFILE_DEBUG) {
            Write-Warning "Failed to create Initialize-Starship function: $($_.Exception.Message)"
        }
    }
    
    # ================================================
    # AUTO-INITIALIZATION
    # ================================================
    
    # Note: Auto-initialization is deferred to Initialize-ProfilePrompt which runs after all fragments load.
    # This ensures all helper modules are available and the prompt system is ready.
    # The Initialize-Starship function is created above and will be called by Initialize-ProfilePrompt.
    
    # Mark fragment as loaded for idempotency tracking
    if (Get-Command Set-FragmentLoaded -ErrorAction SilentlyContinue) {
        Set-FragmentLoaded -FragmentName 'starship'
    }
    
    # Level 2: Verbose debug - function creation verification
    if ($debugLevel -ge 2) {
        $hasStarship = $false
        if (Get-Command Test-CachedCommand -ErrorAction SilentlyContinue) {
            $hasStarship = Test-CachedCommand starship
        }
        else {
            $hasStarship = $null -ne (Get-Command starship -ErrorAction SilentlyContinue)
        }
        
        # Verify function was created
        $funcExists = (Get-Command Initialize-Starship -ErrorAction SilentlyContinue) -ne $null
        if ($funcExists) {
            if ($hasStarship) {
                Write-Host "  [fragment.starship] Starship command available - Initialize-Starship function created, will be initialized by ProfilePrompt" -ForegroundColor DarkGray
            }
            else {
                Write-Host "  [fragment.starship] Starship command not found - Initialize-Starship function created for manual initialization" -ForegroundColor DarkGray
            }
        }
        else {
            # Level 1: Basic debug - function creation failure warning
            if ($debugLevel -ge 1) {
                Write-Warning "[fragment.starship] Initialize-Starship function was not created successfully"
            }
        }
    }
}
catch {
    if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
        Write-StructuredError -ErrorRecord $_ -OperationName 'fragment.starship.load' -Context @{
            fragment_name = 'starship'
            loading_stage = 'fragment-load'
        }
    }
    elseif (Get-Command Write-ProfileError -ErrorAction SilentlyContinue) {
        Write-ProfileError -ErrorRecord $_ -Context "Fragment: starship" -Category 'Fragment'
    }
    else {
        Write-Warning "Failed to load starship fragment: $($_.Exception.Message)"
    }
    
    if (-not $env:PS_PROFILE_DEBUG) {
        return
    }
}
