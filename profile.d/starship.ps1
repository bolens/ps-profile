<#

<#

# Tier: essential
# Dependencies: bootstrap, env
<#

<#
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
    # Remove any existing Initialize-Starship function to ensure we have the latest version
    # This handles cases where the fragment might be re-sourced during development
    Remove-Item Function:Initialize-Starship -Force -ErrorAction SilentlyContinue
    Remove-Item Function:global:Initialize-Starship -Force -ErrorAction SilentlyContinue
    
    # Ensure Test-CachedCommand is available (from bootstrap.ps1)
    # Bootstrap loads first, so this should always be available, but we check for safety
    if (-not (Get-Command Test-CachedCommand -ErrorAction SilentlyContinue)) {
        Write-Warning "Test-CachedCommand not available - Starship fragment may not initialize correctly"
    }
    
    # Load Starship helper modules
    # Use standardized module loading if available, otherwise fall back to manual loading
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
            
            if ($env:PS_PROFILE_DEBUG -and $result.FailureCount -gt 0) {
                Write-Verbose "Loaded $($result.SuccessCount) starship modules (failed: $($result.FailureCount))"
            }
        }
        catch {
            if ($env:PS_PROFILE_DEBUG) {
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
                    }
                    catch {
                        if ($env:PS_PROFILE_DEBUG) {
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
    
    <#
    .SYNOPSIS
        Initializes the Starship prompt for PowerShell.
    .DESCRIPTION
        Sets up Starship as the PowerShell prompt if the starship command is available.
        Uses the standard starship initialization which automatically reads starship.toml.
    #>
    # Create Initialize-Starship function - ensure it's in global scope
    if (-not (Test-Path "Function:\\global:Initialize-Starship")) {
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
                if ($env:PS_PROFILE_DEBUG) {
                    Write-Verbose "Initialize-Starship failed: $($_.Exception.Message)"
                }
                Initialize-SmartPrompt
            }
        }
    }
    
    # ================================================
    # AUTO-INITIALIZATION
    # ================================================
    
    # Initialize starship immediately if available
    # Use Get-Command as fallback if Test-CachedCommand isn't available yet
    $hasStarship = $false
    if (Get-Command Test-CachedCommand -ErrorAction SilentlyContinue) {
        $hasStarship = Test-CachedCommand starship
    }
    else {
        # Fallback to direct check
        $hasStarship = $null -ne (Get-Command starship -ErrorAction SilentlyContinue)
    }
    
    if ($hasStarship) {
        try {
            if ($env:PS_PROFILE_DEBUG) {
                Write-Host "Checking/initializing starship..." -ForegroundColor Yellow
            }
            Initialize-Starship
        }
        catch {
            if ($env:PS_PROFILE_DEBUG) {
                Write-Host "Failed to initialize starship: $($_.Exception.Message)" -ForegroundColor Red
            }
            Write-Warning "Starship initialization failed: $($_.Exception.Message)"
        }
    }
    else {
        if ($env:PS_PROFILE_DEBUG) {
            Write-Host "Starship command not found - will use fallback prompt" -ForegroundColor Yellow
        }
    }
}
catch {
    if (-not $env:PS_PROFILE_DEBUG) {
        return
    }
    
    if (Get-Command Write-ProfileError -ErrorAction SilentlyContinue) {
        Write-ProfileError -ErrorRecord $_ -Context "Fragment: starship" -Category 'Fragment'
    }
    else {
        Write-Warning "Failed to load starship fragment: $($_.Exception.Message)"
    }
}
