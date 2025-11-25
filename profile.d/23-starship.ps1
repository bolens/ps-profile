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
    # Remove any existing Initialize-Starship function to ensure we have the latest version
    # This handles cases where the fragment might be re-sourced during development
    Remove-Item Function:Initialize-Starship -Force -ErrorAction SilentlyContinue
    Remove-Item Function:global:Initialize-Starship -Force -ErrorAction SilentlyContinue
    
    # Ensure Test-HasCommand is available (from 00-bootstrap.ps1)
    # Bootstrap loads first, so this should always be available, but we check for safety
    if (-not (Get-Command Test-HasCommand -ErrorAction SilentlyContinue)) {
        Write-Warning "Test-HasCommand not available - Starship fragment may not initialize correctly"
    }
    
    # ================================================
    # HELPER FUNCTIONS
    # ================================================
    
    <#
    .SYNOPSIS
        Tests if Starship is already initialized.
    .DESCRIPTION
        Checks if the current prompt function is a Starship prompt by examining the script block.
    #>
    function Test-StarshipInitialized {
        $promptCmd = Get-Command prompt -CommandType Function -ErrorAction SilentlyContinue
        if (-not $promptCmd) { return $false }
        
        # Check script block for Starship-specific patterns
        $script = $promptCmd.ScriptBlock.ToString()
        return ($script -match 'starship|Invoke-Native|Invoke-Starship')
    }
    
    <#
    .SYNOPSIS
        Checks if a prompt function needs replacement.
    .DESCRIPTION
        Module-scoped prompts can break when modules are unloaded, so we replace them
        with direct function calls to the starship executable for reliability.
    #>
    function Test-PromptNeedsReplacement {
        param([System.Management.Automation.FunctionInfo]$PromptCmd)
        
        if ($PromptCmd.ModuleName -eq 'starship') { return $true }
        $script = $PromptCmd.ScriptBlock.ToString()
        if ($script -match 'Invoke-Native') { return $true }
        return $false
    }
    
    <#
    .SYNOPSIS
        Builds arguments array for starship prompt command.
    .DESCRIPTION
        Constructs the command-line arguments that Starship needs to render the prompt,
        including terminal width, job count, command status, and execution duration.
    #>
    function Get-StarshipPromptArguments {
        param(
            [bool]$LastCommandSucceeded,
            [int]$LastExitCode
        )
        
        $arguments = @("prompt")
        
        # Terminal width
        $width = 80
        try {
            if ($Host.UI.RawUI.WindowSize.Width) {
                $width = $Host.UI.RawUI.WindowSize.Width
            }
        }
        catch {
            if ($env:PS_PROFILE_DEBUG) {
                Write-Verbose "Failed to get terminal width: $($_.Exception.Message)"
            }
        }
        $arguments += "--terminal-width=$width"
        
        # Job count
        $jobs = @(Get-Job | Where-Object { $_.State -eq 'Running' }).Count
        $arguments += "--jobs=$jobs"
        
        # Command status and duration from history
        $lastCmd = Get-History -Count 1 -ErrorAction SilentlyContinue
        if ($lastCmd) {
            $status = if ($LastCommandSucceeded) { 0 } else { 1 }
            $arguments += "--status=$status"
            
            try {
                $duration = [math]::Round(($lastCmd.EndExecutionTime - $lastCmd.StartExecutionTime).TotalMilliseconds)
                $arguments += "--cmd-duration=$duration"
            }
            catch {
                $arguments += "--cmd-duration=0"
            }
        }
        else {
            $arguments += "--status=0"
        }
        
        return $arguments
    }
    
    <#
    .SYNOPSIS
        Creates a global prompt function that directly calls starship executable.
    .DESCRIPTION
        Creates a prompt function that calls starship directly (bypassing module scope issues).
        This ensures the prompt continues working even if the Starship module is unloaded.
    #>
    function New-StarshipPromptFunction {
        param([string]$StarshipCommandPath)
        
        function global:prompt {
            # Capture state BEFORE any operations
            $lastCommandSucceeded = $?
            $lastExitCode = $LASTEXITCODE
            
            try {
                if (-not $global:StarshipCommand -or -not (Test-Path $global:StarshipCommand)) {
                    $global:LASTEXITCODE = $lastExitCode
                    return "PS $($executionContext.SessionState.Path.CurrentLocation.Path)> "
                }
                
                # Build arguments and call starship executable directly
                $arguments = Get-StarshipPromptArguments -LastCommandSucceeded $lastCommandSucceeded -LastExitCode $lastExitCode
                $promptText = & $global:StarshipCommand @arguments 2>$null
                
                if ($promptText -and $promptText.Trim()) {
                    # Configure PSReadLine for multi-line prompts (Starship may output multiple lines)
                    try {
                        $lineCount = ($promptText.Split("`n").Length - 1)
                        Set-PSReadLineOption -ExtraPromptLineCount $lineCount -ErrorAction SilentlyContinue
                    }
                    catch {
                        if ($env:PS_PROFILE_DEBUG) {
                            Write-Verbose "Failed to set PSReadLine extra prompt line count: $($_.Exception.Message)"
                        }
                    }
                    
                    $global:LASTEXITCODE = $lastExitCode
                    return $promptText
                }
            }
            catch {
                # Fall through to default prompt
            }
            
            # Fallback prompt
            $global:LASTEXITCODE = $lastExitCode
            return "PS $($executionContext.SessionState.Path.CurrentLocation.Path)> "
        }
    }
    
    <#
    .SYNOPSIS
        Ensures Starship module stays loaded to prevent prompt from breaking.
    .DESCRIPTION
        Stores a reference to the Starship module globally to prevent it from being garbage collected.
        This helps maintain prompt functionality even if the module would otherwise be unloaded.
    #>
    function Initialize-StarshipModule {
        $module = Get-Module starship -ErrorAction SilentlyContinue
        if ($module) {
            $global:StarshipModule = $module
            if ($env:PS_PROFILE_DEBUG) {
                Write-Host "Starship module loaded and stored globally" -ForegroundColor Green
            }
        }
        else {
            if ($env:PS_PROFILE_DEBUG) {
                Write-Host "WARNING: Starship module not found after init" -ForegroundColor Yellow
            }
        }
    }
    
    <#
    .SYNOPSIS
        Executes Starship's initialization script and verifies it worked.
    .DESCRIPTION
        Runs `starship init powershell --print-full-init` to get the initialization script,
        writes it to a temp file, executes it, and verifies that a valid prompt function was created.
    #>
    function Invoke-StarshipInitScript {
        param([string]$StarshipCommandPath)
        
        $tempInitScript = [System.IO.Path]::GetTempFileName() + '.ps1'
        try {
            # Get initialization script from starship
            $initOutput = & $StarshipCommandPath init powershell --print-full-init 2>&1
            if ($LASTEXITCODE -ne 0 -or -not $initOutput) {
                throw "Failed to get starship init script (exit code: $LASTEXITCODE)"
            }
            
            # Filter out error messages and empty lines from starship output
            $cleanOutput = $initOutput | Where-Object {
                $_ -notmatch '\[ERROR\]' -and
                $_ -notmatch 'Under a' -and
                $_.Trim() -ne ''
            }
            
            if (-not $cleanOutput) {
                throw "Starship init script output is empty or contains only errors"
            }
            
            # Write to temp file and execute
            $cleanOutput | Out-File -FilePath $tempInitScript -Encoding UTF8 -ErrorAction Stop
            
            if ($env:PS_PROFILE_DEBUG) {
                Write-Host "Executing starship init script..." -ForegroundColor Yellow
            }
            
            . $tempInitScript
            
            # Verify prompt function was created
            $promptFunc = Get-Command prompt -CommandType Function -ErrorAction SilentlyContinue
            if (-not $promptFunc) {
                throw "Starship init script did not create prompt function"
            }
            
            # Verify it's actually a Starship prompt
            $promptScript = $promptFunc.ScriptBlock.ToString()
            if ($promptScript -notmatch 'starship|Invoke-Native') {
                throw "Starship init script did not create a valid prompt function"
            }
            
            return $promptFunc
        }
        finally {
            # Clean up temp file
            if (Test-Path $tempInitScript) {
                Remove-Item $tempInitScript -Force -ErrorAction SilentlyContinue
            }
        }
    }
    
    <#
    .SYNOPSIS
        Updates VS Code's prompt state if VS Code is active.
    #>
    function Update-VSCodePrompt {
        if ($null -ne $Global:__VSCodeState -and $null -ne $Global:__VSCodeState.OriginalPrompt) {
            $Global:__VSCodeState.OriginalPrompt = $function:prompt
            if ($env:PS_PROFILE_DEBUG) {
                Write-Host "Updated VS Code OriginalPrompt with starship" -ForegroundColor Green
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
                        if ($global:StarshipCommand -and (Test-Path $global:StarshipCommand)) {
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
    # SMART FALLBACK PROMPT
    # ================================================
    
    <#
    .SYNOPSIS
        Initializes a smart fallback prompt when Starship is not available.
    .DESCRIPTION
        Sets up an enhanced PowerShell prompt that shows git branch, error status,
        execution time, and other useful information when Starship is not available.
    #>
    function global:Initialize-SmartPrompt {
        try {
            if ($null -ne (Get-Variable -Name "SmartPromptInitialized" -Scope Global -ErrorAction SilentlyContinue)) {
                return
            }
            
            # Store original prompt
            if (-not $global:OriginalPrompt) {
                $global:OriginalPrompt = $function:prompt
            }
            
            # Enhanced prompt function
            function global:prompt {
                $lastCommandSucceeded = $?
                try {
                    $lastExitCode = $LASTEXITCODE
                    $currentPath = $executionContext.SessionState.Path.CurrentLocation.Path
                    $promptParts = @()
                    
                    # User and computer
                    $promptParts += "$env:USERNAME@$env:COMPUTERNAME"
                    
                    # Current directory (shortened)
                    $shortPath = $currentPath -replace [regex]::Escape($env:USERPROFILE), "~"
                    if ($shortPath.Length -gt 40) {
                        $shortPath = "..." + $shortPath.Substring($shortPath.Length - 37)
                    }
                    $promptParts += $shortPath
                    
                    # Git branch (if in git repo)
                    try {
                        if (Test-HasCommand git) {
                            if (Test-Path ".git" -ErrorAction SilentlyContinue) {
                                $gitBranch = & git rev-parse --abbrev-ref HEAD 2>&1
                                $gitExitCode = $LASTEXITCODE
                                if ($gitExitCode -eq 0 -and $gitBranch -and $gitBranch.Trim() -ne "HEAD" -and $gitBranch.Trim() -ne "") {
                                    $promptParts += "git:($($gitBranch.Trim()))"
                                }
                            }
                        }
                    }
                    catch {
                        if ($env:PS_PROFILE_DEBUG) {
                            Write-Verbose "Failed to get git branch for prompt: $($_.Exception.Message)"
                        }
                    }
                    
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
                    catch {
                        if ($env:PS_PROFILE_DEBUG) {
                            Write-Verbose "Failed to check administrator role for prompt: $($_.Exception.Message)"
                        }
                    }
                    
                    # Display prompt
                    $promptString = $promptParts -join " │ "
                    Write-Host $promptString -NoNewline -ForegroundColor Cyan
                    Write-Host "`n❯ " -NoNewline -ForegroundColor Green
                    
                    $global:LASTEXITCODE = $lastExitCode
                    return " "
                }
                catch {
                    Write-Host "PS $($executionContext.SessionState.Path.CurrentLocation.Path)> " -NoNewline -ForegroundColor Yellow
                    return " "
                }
            }
            
            # Track command execution time
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
                $global:LastCommandSucceeded = $?
            }
            
            Set-Variable -Name "SmartPromptInitialized" -Value $true -Scope Global -Force
            if ($env:PS_PROFILE_DEBUG) {
                Write-Verbose "Smart prompt initialized (Starship fallback)"
            }
        }
        catch {
            if ($env:PS_PROFILE_DEBUG) {
                Write-Verbose "Initialize-SmartPrompt failed: $($_.Exception.Message)"
            }
        }
    }
    
    # ================================================
    # AUTO-INITIALIZATION
    # ================================================
    
    # Initialize starship immediately if available
    # Use Get-Command as fallback if Test-HasCommand isn't available yet
    $hasStarship = $false
    if (Get-Command Test-HasCommand -ErrorAction SilentlyContinue) {
        $hasStarship = Test-HasCommand starship
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
        Write-ProfileError -ErrorRecord $_ -Context "Fragment: 23-starship" -Category 'Fragment'
    }
    else {
        Write-Verbose "Starship fragment failed to define initializer: $($_.Exception.Message)"
    }
}
