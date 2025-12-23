<#

<#

# Tier: essential
# Dependencies: bootstrap, env
<#

<#
# oh-my-posh.ps1

Idempotent initialization for oh-my-posh prompt framework.

This fragment checks for the `oh-my-posh` command and runs the same
initialization that used to live in the main profile. It is quiet and
idempotent.
#>

try {
    # Define lazy initializer for oh-my-posh to keep profile startup fast.
    # The prompt proxy function calls Initialize-OhMyPosh on first prompt draw,
    # deferring initialization until actually needed.
    if (-not (Test-Path Function:Initialize-OhMyPosh -ErrorAction SilentlyContinue)) {
        <#
        .SYNOPSIS
            Initializes oh-my-posh prompt framework lazily.
        .DESCRIPTION
            Checks for oh-my-posh command availability and initializes the prompt
            framework by running the shell init script. This is called lazily to
            avoid slowing down profile startup.
        #>
        function Initialize-OhMyPosh {
            try {
                if ($null -ne (Get-Variable -Name 'OhMyPoshInitialized' -Scope Global -ErrorAction SilentlyContinue)) { return }

                $ohCmd = Get-Command oh-my-posh -ErrorAction SilentlyContinue
                if (-not $ohCmd) { return }

                # oh-my-posh generates a shell init script via `init pwsh --print`.
                # We write it to a temp file and dot-source it (instead of using Invoke-Expression)
                # to satisfy PSScriptAnalyzer security rules and allow proper error handling.
                $temp = [System.IO.Path]::GetTempFileName() + '.ps1'
                try {
                    # Execute oh-my-posh init command and capture output
                    $initOutput = & $ohCmd.Source init pwsh --print 2>&1
                    $exitCode = $LASTEXITCODE
                    
                    if ($exitCode -ne 0) {
                        throw "oh-my-posh init command failed with exit code $exitCode"
                    }
                    
                    # Validate that we received output
                    if (-not $initOutput -or ($initOutput | Measure-Object).Count -eq 0) {
                        throw "oh-my-posh init command produced no output"
                    }
                    
                    # Write init script to temp file
                    try {
                        $initOutput | Out-File -FilePath $temp -Encoding UTF8 -ErrorAction Stop
                    }
                    catch {
                        throw "Failed to write oh-my-posh init script to temp file: $($_.Exception.Message)"
                    }
                    
                    # Execute the init script
                    if ($temp -and -not [string]::IsNullOrWhiteSpace($temp) -and (Test-Path -LiteralPath $temp -ErrorAction SilentlyContinue)) {
                        try {
                            . $temp
                        }
                        catch {
                            throw "Failed to execute oh-my-posh init script: $($_.Exception.Message)"
                        }
                    }
                    else {
                        throw "Temp file was not created: $temp"
                    }
                }
                finally {
                    # Always clean up temp file, even if initialization fails
                    if ($temp -and -not [string]::IsNullOrWhiteSpace($temp) -and (Test-Path -LiteralPath $temp -ErrorAction SilentlyContinue)) {
                        try {
                            Remove-Item $temp -Force -ErrorAction Stop
                        }
                        catch {
                            if ($env:PS_PROFILE_DEBUG) {
                                Write-Warning "Failed to clean up temp file '$temp': $($_.Exception.Message)"
                            }
                        }
                    }
                }
                Set-Variable -Name 'OhMyPoshInitialized' -Value $true -Scope Global -Force
                if ($env:PS_PROFILE_DEBUG) { Write-Verbose "oh-my-posh initialized via $($ohCmd.Source)" }
            }
            catch {
                if ($env:PS_PROFILE_DEBUG) { Write-Verbose "Initialize-OhMyPosh failed: $($_.Exception.Message)" }
            }
        }
    }

    # Only install proxy prompt if no Prompt function exists (don't override existing configuration)
    if (Get-Command -Name prompt -CommandType Function -ErrorAction SilentlyContinue) {
        return
    }
    
    # If Starship is available, let it handle prompt initialization (loaded by 23-starship.ps1)
    # Starship and oh-my-posh are mutually exclusive prompt frameworks
    if (Test-CachedCommand starship) {
        if ($env:PS_PROFILE_DEBUG) { Write-Host "Starship detected, skipping oh-my-posh proxy prompt" -ForegroundColor Cyan }
        return
    }

    # Initialize global variables for prompt optimization
    if (-not (Get-Variable -Name 'OhMyPoshRealPromptScriptBlock' -Scope Global -ErrorAction SilentlyContinue)) {
        $global:OhMyPoshRealPromptScriptBlock = $null
    }
    if (-not (Get-Variable -Name 'OhMyPoshStarshipInitialized' -Scope Global -ErrorAction SilentlyContinue)) {
        $global:OhMyPoshStarshipInitialized = $false
    }

    # Create proxy prompt function that lazy-loads oh-my-posh on first invocation.
    # After initialization, delegates to the real prompt function registered by oh-my-posh.
    # Uses cached ScriptBlock reference to avoid expensive Get-Command calls.
    <#
    .SYNOPSIS
        PowerShell prompt function with lazy oh-my-posh initialization.
    .DESCRIPTION
        This prompt function initializes oh-my-posh on first invocation and then
        delegates to the real prompt function registered by oh-my-posh. Falls back
        to a minimal prompt if initialization fails.
    #>
    function prompt {
        # Fast check: Use cached initialization state
        $ohInit = $false
        try { 
            $ohInit = $null -ne (Get-Variable -Name 'OhMyPoshInitialized' -Scope Global -ErrorAction SilentlyContinue) 
        } 
        catch { 
            $ohInit = $false 
        }
        
        # Initialize oh-my-posh on first call only
        if (-not $ohInit) { 
            Initialize-OhMyPosh 
        }

        # Initialize Starship once if available (some themes may depend on it)
        if (-not $global:OhMyPoshStarshipInitialized) {
            # Cache the check result to avoid repeated Get-Command calls
            $hasInitializeStarship = $false
            if (Test-Path 'Function:\Initialize-Starship' -ErrorAction SilentlyContinue) {
                $hasInitializeStarship = $true
            }
            elseif (Test-Path 'Function:\global:Initialize-Starship' -ErrorAction SilentlyContinue) {
                $hasInitializeStarship = $true
            }
            elseif ((Get-Command -Name 'Initialize-Starship' -ErrorAction SilentlyContinue) -ne $null) {
                $hasInitializeStarship = $true
            }
            
            if ($hasInitializeStarship) {
                try { 
                    & Initialize-Starship 
                    $global:OhMyPoshStarshipInitialized = $true
                }
                catch {
                    $global:OhMyPoshStarshipInitialized = $true  # Mark as attempted to avoid retry
                    if ($env:PS_PROFILE_DEBUG) {
                        if (Test-Path 'Function:\Write-ProfileError' -ErrorAction SilentlyContinue) {
                            Write-ProfileError -ErrorRecord $_ -Context "Fragment: oh-my-posh (Initialize-Starship)" -Category 'Fragment'
                        }
                        else {
                            Write-Verbose "Failed to initialize Starship from oh-my-posh fragment: $($_.Exception.Message)"
                        }
                    }
                }
            }
            else {
                $global:OhMyPoshStarshipInitialized = $true  # Mark as checked
            }
        }

        # Check if oh-my-posh registered a new Prompt function and delegate to it
        # Use cached ScriptBlock reference to avoid expensive Get-Command calls
        if ($global:OhMyPoshRealPromptScriptBlock) {
            try {
                return & $global:OhMyPoshRealPromptScriptBlock
            }
            catch {
                # If delegation fails, fall back to minimal prompt (don't break interactive session)
                if ($env:PS_PROFILE_DEBUG) {
                    Write-Verbose "Failed to invoke cached prompt function: $($_.Exception.Message)"
                }
                # Clear cached reference on error to allow retry
                $global:OhMyPoshRealPromptScriptBlock = $null
            }
        }
        else {
            # Only check for new prompt function if we haven't cached it yet (once per session)
            # Use fast function provider check to avoid expensive Get-Command
            $newPromptFound = $false
            try {
                # Fast check: Test function provider directly (much faster than Get-Command)
                if (Test-Path 'Function:\prompt' -ErrorAction SilentlyContinue) {
                    $currentPrompt = Get-Item 'Function:\prompt' -ErrorAction SilentlyContinue
                    if ($currentPrompt -and $currentPrompt.ScriptBlock) {
                        $currentScriptBlock = $currentPrompt.ScriptBlock
                        $currentScriptBlockString = $currentScriptBlock.ToString()
                        # Check if this is a different prompt (oh-my-posh registered its own)
                        # Look for oh-my-posh indicators in the ScriptBlock
                        if ($currentScriptBlockString -match 'oh-my-posh|Invoke-Native|ohmyposh') {
                            # oh-my-posh has registered its own prompt
                            $global:OhMyPoshRealPromptScriptBlock = $currentScriptBlock
                            $newPromptFound = $true
                        }
                    }
                }
            }
            catch {
                # Fall through to minimal prompt on any error
            }
            
            if ($newPromptFound -and $global:OhMyPoshRealPromptScriptBlock) {
                try {
                    return & $global:OhMyPoshRealPromptScriptBlock
                }
                catch {
                    if ($env:PS_PROFILE_DEBUG) {
                        Write-Verbose "Failed to invoke registered prompt function: $($_.Exception.Message)"
                    }
                    $global:OhMyPoshRealPromptScriptBlock = $null
                }
            }
        }

        # Fallback: minimal prompt if oh-my-posh initialization failed or no prompt was registered
        # Use fast path access instead of Get-Location
        $user = $env:USERNAME
        $hostName = $env:COMPUTERNAME
        $cwd = $executionContext.SessionState.Path.CurrentLocation.Path
        return "$user@$hostName $cwd > "
    }

}
catch {
    if ($env:PS_PROFILE_DEBUG) { Write-Verbose "oh-my-posh fragment failed: $($_.Exception.Message)" }
}
