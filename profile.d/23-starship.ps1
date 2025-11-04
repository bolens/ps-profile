<#
# 23-starship.ps1

Idempotent, quiet initialization of the Starship prompt for PowerShell with smart fallback.

Behavior:
 - If the `starship` command is available, this fragment will call
   `starship init powershell` and execute the generated initialization
   code.
 - If starship is not available, provides a smart fallback prompt with
   git branch, error status, timing, and other useful information.
 - The fragment is idempotent: it will only initialize once per session.
 - It is quiet when dot-sourced (returns no output) so the interactive
   shell startup remains clean.

Notes:
 - Prefer creating a global flag `$Global:StarshipInitialized` instead of
   relying on prompt function inspection; this keeps the check cheap.
 - If `PS_PROFILE_DEBUG` is set in your environment, this fragment will
   emit a verbose message to help debugging.
#>

try {
    # Define a lazy initializer for starship so startup remains snappy. Consumers
    # (like the prompt proxy) can call Initialize-Starship to set up starship
    # at the first prompt draw instead of at profile load.
    if (-not (Test-Path Function:Initialize-Starship -ErrorAction SilentlyContinue)) {
        <#
        .SYNOPSIS
            Initializes the Starship prompt for PowerShell.
        .DESCRIPTION
            Sets up Starship as the PowerShell prompt if the starship command is available.
            Uses lazy initialization to avoid slowing down profile startup. Creates a global
            flag to ensure initialization happens only once per session.
        #>
        function Initialize-Starship {
            try {
                if ($null -ne (Get-Variable -Name 'StarshipInitialized' -Scope Global -ErrorAction SilentlyContinue)) { return }
                $starCmd = Get-Command starship -ErrorAction SilentlyContinue
                if (-not $starCmd) {
                    # Starship not available, set up smart fallback prompt
                    Initialize-SmartPrompt
                    return
                }
                # Use a simpler approach: define the prompt function directly
                function global:prompt {
                    # Capture status immediately at prompt start
                    $lastCommandSucceeded = $?
                    $lastExitCode = $LASTEXITCODE

                    # @ makes sure the result is an array even if single or no values are returned
                    $jobs = @(Get-Job | Where-Object { $_.State -eq 'Running' }).Count

                    $cwd = Get-Location
                    $arguments = @(
                        "prompt"
                        "--path=$($cwd.Path)",
                        "--logical-path=$($cwd.Path)",
                        "--terminal-width=$($Host.UI.RawUI.WindowSize.Width)",
                        "--jobs=$($jobs)"
                    )

                    # Determine status based on last command success
                    $lastExitCodeForPrompt = if ($lastCommandSucceeded) { 0 } else { $lastExitCode -or 1 }

                    if ($lastCmd = Get-History -Count 1) {
                        $duration = [math]::Round(($lastCmd.EndExecutionTime - $lastCmd.StartExecutionTime).TotalMilliseconds)
                        $arguments += "--cmd-duration=$($duration)"
                    }

                    $arguments += "--status=$($lastExitCodeForPrompt)"

                    # Invoke Starship
                    try {
                        $promptText = & $starCmd.Source @arguments 2>$null
                        if ($promptText) {
                            $promptText
                        }
                        else {
                            "❯ "
                        }
                    }
                    catch {
                        "❯ "
                    }
                }

                Set-Variable -Name 'StarshipInitialized' -Value $true -Scope Global -Force
                if ($env:PS_PROFILE_DEBUG) { Write-Verbose "Starship initialized via $($starCmd.Source)" }
                else {
                    # Fallback to smart prompt if starship init fails
                    Initialize-SmartPrompt
                }
            }
            catch {
                if ($env:PS_PROFILE_DEBUG) { Write-Verbose "Initialize-Starship failed: $($_.Exception.Message)" }
                # Fallback to smart prompt on error
                Initialize-SmartPrompt
            }
        }
    }

    # Smart fallback prompt with useful information
    if (-not (Test-Path Function:Initialize-SmartPrompt -ErrorAction SilentlyContinue)) {
        <#
        .SYNOPSIS
            Initializes a smart fallback prompt when Starship is not available.
        .DESCRIPTION
            Sets up an enhanced PowerShell prompt that shows git branch, error status,
            execution time, and other useful information when Starship is not available.
        #>
        function Initialize-SmartPrompt {
            try {
                if ($null -ne (Get-Variable -Name 'SmartPromptInitialized' -Scope Global -ErrorAction SilentlyContinue)) { return }

                # Store the original prompt function
                if (-not $global:OriginalPrompt) {
                    $global:OriginalPrompt = $function:prompt
                }

                # Enhanced prompt function
                function global:prompt {
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
                        $shortPath = $currentPath -replace [regex]::Escape($env:USERPROFILE), '~'
                        if ($shortPath.Length -gt 40) {
                            $shortPath = '...' + $shortPath.Substring($shortPath.Length - 37)
                        }
                        $promptParts += $shortPath

                        # Git branch (if in git repo)
                        $gitBranch = $null
                        try {
                            if (Test-Path '.git' -or (Get-Command git -ErrorAction SilentlyContinue)) {
                                $gitBranch = & git rev-parse --abbrev-ref HEAD 2>$null
                                if ($gitBranch -and $gitBranch -ne 'HEAD') {
                                    $promptParts += "git:($gitBranch)"
                                }
                            }
                        }
                        catch { }

                        # Error indicator
                        if ($lastExitCode -ne 0) {
                            $promptParts += "❌$lastExitCode"
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
                        catch { }

                        # Join parts with separators
                        $promptString = $promptParts -join ' │ '

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

                # Set up execution time tracking
                if (-not $global:OriginalPromptFunction) {
                    $global:OriginalPromptFunction = $function:prompt
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
                }

                Set-Variable -Name 'SmartPromptInitialized' -Value $true -Scope Global -Force
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
