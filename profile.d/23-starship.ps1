<#
# 23-starship.ps1

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
    # Define a lazy initializer for starship
    # Always remove and redefine to ensure we have the latest version, especially after profile reloads
    # This prevents cached function definitions from causing issues
    Remove-Item Function:Initialize-Starship -Force -ErrorAction SilentlyContinue
    Remove-Item Function:global:Initialize-Starship -Force -ErrorAction SilentlyContinue
    
    <#
    .SYNOPSIS
        Initializes the Starship prompt for PowerShell.
    .DESCRIPTION
        Sets up Starship as the PowerShell prompt if the starship command is available.
        Uses the standard starship initialization which automatically reads starship.toml.
    #>
    function Initialize-Starship {
        try {
            # Check if already initialized - make this truly idempotent
            $isInitialized = (Get-Variable -Name "StarshipInitialized" -Scope Global -ErrorAction SilentlyContinue) -and
            (Get-Variable -Name "StarshipActive" -Scope Global -ErrorAction SilentlyContinue) -and
            (Get-Command prompt -CommandType Function -ErrorAction SilentlyContinue)
            
            if ($isInitialized) {
                # Verify the prompt function is actually a Starship prompt
                $promptFunc = Get-Command prompt -CommandType Function
                $promptScript = $promptFunc.ScriptBlock.ToString()
                # Starship's prompt uses Invoke-Native or calls starship executable
                $isStarshipPrompt = $promptScript -match 'starship|Invoke-Native|Invoke-Starship'
                
                if ($isStarshipPrompt) {
                    # Already initialized with valid Starship prompt - ensure module stays loaded
                    # Create wrapper to ensure prompt is always accessible
                    $starshipModule = Get-Module starship -ErrorAction SilentlyContinue
                    if ($starshipModule) {
                        $global:StarshipModule = $starshipModule
                        
                        # Ensure wrapper exists
                        $moduleRef = $starshipModule
                        if (-not (Get-Command prompt -CommandType Function -ErrorAction SilentlyContinue) -or 
                            (Get-Command prompt).ModuleName -ne $null) {
                            # Create wrapper function
                            function global:prompt {
                                try {
                                    if ($moduleRef) {
                                        $modulePrompt = $moduleRef.Invoke({ Get-Command prompt -CommandType Function -ErrorAction SilentlyContinue })
                                        if ($modulePrompt) {
                                            $moduleRef.Invoke({ & prompt })
                                            return
                                        }
                                    }
                                    $currentPrompt = Get-Command prompt -CommandType Function -ErrorAction SilentlyContinue
                                    if ($currentPrompt -and $currentPrompt.ModuleName -eq 'starship') {
                                        & $currentPrompt.ScriptBlock
                                    }
                                    else {
                                        "PS $($executionContext.SessionState.Path.CurrentLocation.Path)> "
                                    }
                                }
                                catch {
                                    "PS $($executionContext.SessionState.Path.CurrentLocation.Path)> "
                                }
                            }
                        }
                        
                        if ($env:PS_PROFILE_DEBUG) { Write-Host "Starship already initialized, prompt verified and active" -ForegroundColor Green }
                        return
                    }
                    else {
                        # Module is missing but prompt function exists - module may have been unloaded
                        # Clear initialization state and re-initialize to restore the module
                        if ($env:PS_PROFILE_DEBUG) { Write-Host "Starship module missing, clearing state and re-initializing..." -ForegroundColor Yellow }
                        Remove-Variable -Name "StarshipInitialized" -Scope Global -ErrorAction SilentlyContinue
                        Remove-Variable -Name "StarshipActive" -Scope Global -ErrorAction SilentlyContinue
                        Remove-Variable -Name "StarshipModule" -Scope Global -ErrorAction SilentlyContinue
                        # Remove the orphaned prompt function
                        Remove-Item Function:prompt -Force -ErrorAction SilentlyContinue
                        Remove-Item Function:global:prompt -Force -ErrorAction SilentlyContinue
                        # Fall through to re-initialization
                    }
                }
            }
                
            # Not initialized or prompt is invalid - proceed with initialization

            $starCmd = Get-Command starship -ErrorAction SilentlyContinue
            if (-not $starCmd) {
                if ($env:PS_PROFILE_DEBUG) { Write-Host "Starship not found, using smart prompt" -ForegroundColor Yellow }
                # Starship not available, set up smart fallback prompt
                Initialize-SmartPrompt
                return
            }

            if ($env:PS_PROFILE_DEBUG) { Write-Host "Starship found at: $($starCmd.Source)" -ForegroundColor Green }

            # Use starship's official initialization script
            # This properly sets up all hooks and features that Starship needs
            $tempInitScript = [System.IO.Path]::GetTempFileName() + '.ps1'
            try {
                # Get the initialization script from starship
                $initOutput = & $starCmd.Source init powershell --print-full-init 2>&1
                if ($LASTEXITCODE -ne 0 -or -not $initOutput) {
                    throw "Failed to get starship init script"
                }

                # Write to temp file and dot-source it (avoiding Invoke-Expression)
                # Filter out any error messages that starship might output
                $cleanOutput = $initOutput | Where-Object { $_ -notmatch '\[ERROR\]' -and $_ -notmatch 'Under a' } | Where-Object { $_.Trim() -ne '' }
                if (-not $cleanOutput) {
                    throw "Starship init script output is empty or contains only errors"
                }
                $cleanOutput | Out-File -FilePath $tempInitScript -Encoding UTF8 -ErrorAction Stop
                    
                if ($env:PS_PROFILE_DEBUG) { Write-Host "Executing starship init script..." -ForegroundColor Yellow }
                # Dot-source the initialization script (this will create the prompt function)
                try {
                    . $tempInitScript
                }
                catch {
                    if ($env:PS_PROFILE_DEBUG) { Write-Host "Error executing starship init script: $($_.Exception.Message)" -ForegroundColor Red }
                    throw
                }
                    
                # Starship's init script creates function global:prompt automatically
                # It may be created inside the starship module, but it's still globally accessible
                # We need to ensure the module stays loaded and the prompt remains callable
                $global:StarshipCommand = $starCmd.Source
                
                if (Get-Command prompt -CommandType Function -ErrorAction SilentlyContinue) {
                    $promptFunc = Get-Command prompt -CommandType Function
                    # Verify it's actually the starship prompt
                    $promptScript = $promptFunc.ScriptBlock.ToString()
                    if ($promptScript -match 'starship|Invoke-Native') {
                        # CRITICAL: Keep the starship module loaded and create a global wrapper
                        # The prompt function MUST stay in the module scope to access module functions like Invoke-Native
                        # But we create a global wrapper to ensure PowerShell always finds it
                        $starshipModule = Get-Module starship -ErrorAction SilentlyContinue
                        if ($starshipModule) {
                            # Keep module in memory by storing a reference (prevents garbage collection)
                            $global:StarshipModule = $starshipModule
                            
                            # Store reference to module's prompt function for the wrapper
                            $starshipPromptRef = $promptFunc
                            
                            # Create a global wrapper function that calls the module's prompt
                            # Starship creates 'function global:prompt' from within the module,
                            # but we create our own wrapper to ensure it's always accessible
                            # Store the module reference in the wrapper's closure
                            $moduleRef = $starshipModule
                            function global:prompt {
                                try {
                                    # Try to get the prompt from the starship module
                                    if ($moduleRef) {
                                        # Get the prompt function from the module's session state
                                        $modulePrompt = $moduleRef.Invoke({ Get-Command prompt -CommandType Function -ErrorAction SilentlyContinue })
                                        if ($modulePrompt) {
                                            # Invoke the prompt function in the module's context
                                            $moduleRef.Invoke({ & prompt })
                                            return
                                        }
                                    }
                                    
                                    # Fallback: try to get prompt function normally
                                    $currentPrompt = Get-Command prompt -CommandType Function -ErrorAction SilentlyContinue
                                    if ($currentPrompt -and $currentPrompt.ModuleName -eq 'starship') {
                                        # Call the function by invoking its scriptblock
                                        & $currentPrompt.ScriptBlock
                                    }
                                    else {
                                        # Final fallback
                                        "PS $($executionContext.SessionState.Path.CurrentLocation.Path)> "
                                    }
                                }
                                catch {
                                    # Error handling - fallback to simple prompt
                                    "PS $($executionContext.SessionState.Path.CurrentLocation.Path)> "
                                }
                            }
                            
                            if ($env:PS_PROFILE_DEBUG) { Write-Host "Starship module loaded and global wrapper created" -ForegroundColor Green }
                        }
                        else {
                            if ($env:PS_PROFILE_DEBUG) { Write-Host "WARNING: Starship module not found - prompt may not work correctly" -ForegroundColor Yellow }
                        }
                        
                        $global:StarshipPromptActive = $true
                        if ($env:PS_PROFILE_DEBUG) { Write-Host "Starship prompt function created successfully" -ForegroundColor Green }
                    }
                    else {
                        throw "Starship init script did not create a valid prompt function"
                    }
                }
                else {
                    throw "Starship init script did not create prompt function"
                }
                    
                if ($env:PS_PROFILE_DEBUG) { Write-Host "Starship init script executed successfully" -ForegroundColor Green }
            }
            catch {
                if ($env:PS_PROFILE_DEBUG) { Write-Host "Starship init failed: $($_.Exception.Message), trying fallback..." -ForegroundColor Yellow }
                # Store starship command path globally for use in fallback prompt function
                $global:StarshipCommand = $starCmd.Source
                # Fallback: manually create prompt function if init script fails
                function global:prompt {
                    $origDollarQuestion = $global:?
                    $origLastExitCode = $global:LASTEXITCODE

                    # Get job count
                    $jobs = @(Get-Job | Where-Object { $_.State -eq 'Running' }).Count

                    # Build arguments for starship
                    $arguments = @(
                        "prompt"
                        "--terminal-width=$($Host.UI.RawUI.WindowSize.Width)",
                        "--jobs=$($jobs)"
                    )

                    # Add command duration and status if we have history
                    if ($lastCmd = Get-History -Count 1) {
                        if (-not $origDollarQuestion) {
                            $arguments += "--status=1"
                        }
                        else {
                            $arguments += "--status=0"
                        }
                        $duration = [math]::Round(($lastCmd.EndExecutionTime - $lastCmd.StartExecutionTime).TotalMilliseconds)
                        $arguments += "--cmd-duration=$($duration)"
                    }
                    else {
                        $arguments += "--status=0"
                    }

                    # Call starship using the global command path
                    try {
                        if ($global:StarshipCommand) {
                            $promptText = & $global:StarshipCommand @arguments 2>$null
                            if ($promptText -and $promptText.Trim()) {
                                # Set PSReadLine option for multi-line prompts
                                Set-PSReadLineOption -ExtraPromptLineCount ($promptText.Split("`n").Length - 1) -ErrorAction SilentlyContinue
                                return $promptText
                            }
                        }
                    }
                    catch {
                        if ($env:PS_PROFILE_DEBUG) { Write-Host "Starship prompt failed: $($_.Exception.Message)" -ForegroundColor Red }
                    }

                    # Fallback prompt
                    return "PS $($executionContext.SessionState.Path.CurrentLocation.Path)> "
                }
                $global:StarshipPromptActive = $true
            }
            finally {
                # Clean up temp file
                if (Test-Path $tempInitScript) {
                    Remove-Item $tempInitScript -Force -ErrorAction SilentlyContinue
                }
            }

            # Ensure the prompt function persists and override any existing one
            # Store reference to starship command for persistence
            $global:StarshipCommand = $starCmd.Source

            # Final safeguard: ensure prompt function exists and module stays loaded
            if (Get-Command prompt -CommandType Function -ErrorAction SilentlyContinue) {
                $promptFunc = Get-Command prompt -CommandType Function
                $promptScript = $promptFunc.ScriptBlock.ToString()
                
                # Verify it's still the starship prompt (not overridden by another fragment)
                if ($promptScript -match 'starship|Invoke-Native') {
                    # Ensure starship module stays loaded - DO NOT copy the prompt function
                    # The prompt must stay in the module scope to access module functions
                    $starshipModule = Get-Module starship -ErrorAction SilentlyContinue
                    if ($starshipModule) {
                        $global:StarshipModule = $starshipModule
                    }
                    
                    if ($env:PS_PROFILE_DEBUG) { Write-Host "Starship prompt function verified (staying in module scope)" -ForegroundColor Green }
                }
                else {
                    # Prompt was overridden - this shouldn't happen, but log it
                    if ($env:PS_PROFILE_DEBUG) { Write-Host "WARNING: Prompt function was overridden after starship initialization" -ForegroundColor Yellow }
                }
            }
            else {
                # This should not happen - starship init should have created it
                throw "Prompt function missing after starship initialization"
            }

            # Update VS Code's OriginalPrompt if VS Code is active
            if ($null -ne $Global:__VSCodeState -and $null -ne $Global:__VSCodeState.OriginalPrompt) {
                $Global:__VSCodeState.OriginalPrompt = $function:prompt
                if ($env:PS_PROFILE_DEBUG) { Write-Host "Updated VS Code OriginalPrompt with starship" -ForegroundColor Green }
            }

            Set-Variable -Name "StarshipInitialized" -Value $true -Scope Global -Force
            Set-Variable -Name "StarshipActive" -Value $true -Scope Global -Force

            if ($env:PS_PROFILE_DEBUG) { Write-Host "Starship prompt initialized successfully" -ForegroundColor Green }
        }
        catch {
            if ($env:PS_PROFILE_DEBUG) { Write-Verbose "Initialize-Starship failed: $($_.Exception.Message)" }
            # Fallback to smart prompt on error
            Initialize-SmartPrompt
        }
    }

    # Initialize starship immediately if available
    # Always call Initialize-Starship - it will handle checking if already initialized
    # and verify the prompt function is correct
    if (Get-Command starship -ErrorAction SilentlyContinue) {
        try {
            if ($env:PS_PROFILE_DEBUG) { Write-Host "Checking/initializing starship..." -ForegroundColor Yellow }
            Initialize-Starship
        }
        catch {
            if ($env:PS_PROFILE_DEBUG) { Write-Host "Failed to initialize starship: $($_.Exception.Message)" -ForegroundColor Red }
            # If initialization fails, it will be tried again later
        }
    }

    # Smart fallback prompt with useful information
    if (-not (Test-Path Function:Initialize-SmartPrompt -ErrorAction SilentlyContinue)) {
        <#  <#  <#  <#
        .SYNOPSIS
            Initializes a smart fallback prompt when Starship is not available.
        .DESCRIPTION
            Sets up an enhanced PowerShell prompt that shows git branch, error status,
            execution time, and other useful information when Starship is not available.
        #>
        function Initialize-SmartPrompt {
            try {
                if ($null -ne (Get-Variable -Name "SmartPromptInitialized" -Scope Global -ErrorAction SilentlyContinue)) { return }

                # Store the original prompt function
                if (-not $global:OriginalPrompt) {
                    $global:OriginalPrompt = $function:prompt
                }

                # Enhanced prompt function
                function global:prompt {
                    # Capture command success status BEFORE any other operations
                    $lastCommandSucceeded = $?
                    try {
                        $lastExitCode = $LASTEXITCODE
                        $currentPath = $executionContext.SessionState.Path.CurrentLocation.Path

                        # Build prompt segments
                        $promptParts = @()

                        # User and computer
                        $user = $env:USERNAME
                        $computer = $env:COMPUTERNAME
                        $promptParts += "$user@$computer"

                        # Current directory (shortened)
                        $shortPath = $currentPath -replace [regex]::Escape($env:USERPROFILE), "~"
                        if ($shortPath.Length -gt 40) {
                            $shortPath = "..." + $shortPath.Substring($shortPath.Length - 37)
                        }
                        $promptParts += $shortPath

                        # Git branch (if in git repo)
                        $gitBranch = $null
                        try {
                            if (Test-Path ".git" -or (Get-Command git -ErrorAction SilentlyContinue)) {
                                $gitBranch = & git rev-parse --abbrev-ref HEAD 2>$null
                                if ($gitBranch -and $gitBranch -ne "HEAD") {
                                    $promptParts += "git:($gitBranch)"
                                }
                            }
                        }
                        catch { }

                        # Execution time (if available)
                        if ($global:LastCommandDuration) {
                            $duration = $global:LastCommandDuration.TotalMilliseconds
                            if ($duration -gt 1000) {
                                $promptParts += ("{0:N0}ms" -f $duration)
                            }
                        }

                        # Admin indicator
                        try {
                            $currentPrincipal = [Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
                            if ($currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
                                $promptParts += "🔑"
                            }
                        }
                        catch { }

                        # Join parts with separators
                        $promptString = $promptParts -join " │ "

                        # Color the prompt
                        Write-Host "$promptString" -NoNewline -ForegroundColor Cyan
                        Write-Host "`n❯ " -NoNewline -ForegroundColor Green

                        # Reset LASTEXITCODE
                        $global:LASTEXITCODE = $lastExitCode

                        return " "
                    }
                    catch {
                        # Fallback to simple prompt on error
                        Write-Host "PS $($executionContext.SessionState.Path.CurrentLocation.Path)> " -NoNewline -ForegroundColor Yellow
                        return " "
                    }
                }

                # Track command execution time and success status
                $ExecutionContext.SessionState.InvokeCommand.PreCommandLookupAction = {
                    param($command, $eventArgs)
                    $global:CommandStartTime = [DateTime]::Now
                }

                $ExecutionContext.SessionState.InvokeCommand.PostCommandLookupAction = {
                    param($command, $eventArgs)
                    if ($global:CommandStartTime) {
                        $global:LastCommandDuration = [DateTime]::Now - $global:CommandStartTime
                        $global:CommandStartTime = $null
                    }
                    # Track if the last command succeeded
                    $global:LastCommandSucceeded = $?
                }

                Set-Variable -Name "SmartPromptInitialized" -Value $true -Scope Global -Force
                if ($env:PS_PROFILE_DEBUG) { Write-Verbose "Smart prompt initialized (Starship fallback)" }
            }
            catch {
                if ($env:PS_PROFILE_DEBUG) { Write-Verbose "Initialize-SmartPrompt failed: $($_.Exception.Message)" }
            }
        }
    }
}
catch {
    if ($env:PS_PROFILE_DEBUG) { Write-Verbose "Starship fragment failed to define initializer: $($_.Exception.Message)" }
}
