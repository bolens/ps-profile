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
    if (-not (Test-Path Function:Initialize-Starship -ErrorAction SilentlyContinue)) {
        <#
        .SYNOPSIS
            Initializes the Starship prompt for PowerShell.
        .DESCRIPTION
            Sets up Starship as the PowerShell prompt if the starship command is available.
            Uses the standard starship initialization which automatically reads starship.toml.
        #>
        function Initialize-Starship {
            try {
                # Check if already initialized, but verify the prompt function actually exists
                if ($null -ne (Get-Variable -Name "StarshipInitialized" -Scope Global -ErrorAction SilentlyContinue)) {
                    # Verify the prompt function exists and is global
                    $promptFunc = Get-Command prompt -CommandType Function -ErrorAction SilentlyContinue
                    if ($promptFunc) {
                        # Force remove and re-set to ensure it's global and not shadowed
                        Remove-Item Function:prompt -Force -ErrorAction SilentlyContinue
                        Remove-Item Function:global:prompt -Force -ErrorAction SilentlyContinue
                        # Ensure it's global
                        $global:prompt = $promptFunc.ScriptBlock
                        Set-Item -Path Function:global:prompt -Value $promptFunc.ScriptBlock -Force | Out-Null
                        if ($env:PS_PROFILE_DEBUG) { Write-Host "Starship already initialized, verified and re-enforced prompt function" -ForegroundColor Yellow }
                        return
                    }
                    else {
                        # Prompt function missing, need to re-initialize
                        if ($env:PS_PROFILE_DEBUG) { Write-Host "Starship marked as initialized but prompt function missing, re-initializing..." -ForegroundColor Yellow }
                        Remove-Variable -Name "StarshipInitialized" -Scope Global -ErrorAction SilentlyContinue
                        Remove-Variable -Name "StarshipActive" -Scope Global -ErrorAction SilentlyContinue
                    }
                }

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
                    $initOutput = & $starCmd.Source init powershell --print 2>&1
                    if ($LASTEXITCODE -ne 0 -or -not $initOutput) {
                        throw "Failed to get starship init script"
                    }

                    # Write to temp file and dot-source it (avoiding Invoke-Expression)
                    $initOutput | Out-File -FilePath $tempInitScript -Encoding UTF8 -ErrorAction Stop
                    
                    if ($env:PS_PROFILE_DEBUG) { Write-Host "Executing starship init script..." -ForegroundColor Yellow }
                    # Dot-source the initialization script (this will create/override the prompt function)
                    . $tempInitScript
                    
                    # Ensure the prompt function is set globally and persists
                    # The starship init script should have created it, but we ensure it's global
                    if (Get-Command prompt -CommandType Function -ErrorAction SilentlyContinue) {
                        # Get the prompt function and ensure it's global
                        $promptFunc = Get-Command prompt -CommandType Function
                        # Always copy to global scope to ensure it persists
                        $global:prompt = $promptFunc.ScriptBlock
                        # Also explicitly set it as a global function to ensure it persists
                        Set-Item -Path Function:global:prompt -Value $promptFunc.ScriptBlock -Force | Out-Null
                        # Mark that Starship prompt is active
                        $global:StarshipPromptActive = $true
                        if ($env:PS_PROFILE_DEBUG) { Write-Host "Starship prompt function confirmed active and set globally" -ForegroundColor Green }
                    }
                    else {
                        # If prompt function wasn't created, force create it using starship command
                        if ($env:PS_PROFILE_DEBUG) { Write-Host "Prompt function not found after init, creating manually..." -ForegroundColor Yellow }
                        $global:StarshipCommand = $starCmd.Source
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

                # Final safeguard: ensure prompt function is global and persists
                # This prevents other profile fragments from overriding it
                # Remove any non-global prompt functions first
                if (Get-Command prompt -CommandType Function -ErrorAction SilentlyContinue) {
                    $promptFunc = Get-Command prompt -CommandType Function
                    # Force remove any existing prompt functions (including from other scopes)
                    Remove-Item Function:prompt -Force -ErrorAction SilentlyContinue
                    Remove-Item Function:global:prompt -Force -ErrorAction SilentlyContinue
                    # Now set it explicitly as global
                    $global:prompt = $promptFunc.ScriptBlock
                    Set-Item -Path Function:global:prompt -Value $promptFunc.ScriptBlock -Force | Out-Null
                    if ($env:PS_PROFILE_DEBUG) { Write-Host "Re-enforced global prompt function (removed any conflicting prompts)" -ForegroundColor Green }
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
    }

    # Initialize starship immediately if available
    if ($null -eq (Get-Variable -Name "StarshipInitialized" -Scope Global -ErrorAction SilentlyContinue) -and
        (Get-Command starship -ErrorAction SilentlyContinue)) {
        try {
            if ($env:PS_PROFILE_DEBUG) { Write-Host "Initializing starship..." -ForegroundColor Yellow }
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
