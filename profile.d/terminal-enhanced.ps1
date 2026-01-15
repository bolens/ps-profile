# ===============================================
# terminal-enhanced.ps1
# Enhanced terminal tools
# ===============================================
# Tier: optional
# Dependencies: bootstrap, env

<#
.SYNOPSIS
    Enhanced terminal tools fragment.

.DESCRIPTION
    Provides wrapper functions for terminal emulators and multiplexers:
    - Terminal Emulators: Alacritty, Kitty, WezTerm, Tabby, Windows Terminal, Hyper, Terminator
    - Terminal Multiplexers: tmux, screen

.NOTES
    All functions gracefully degrade when tools are not installed.
    This module provides terminal emulator and multiplexer capabilities.
#>

try {
    # Idempotency check: skip if already loaded
    if (Get-Command Test-FragmentLoaded -ErrorAction SilentlyContinue) {
        if (Test-FragmentLoaded -FragmentName 'terminal-enhanced') { return }
    }
    
    # Import Command module for Get-ToolInstallHint (if not already available)
    if (-not (Get-Command Get-ToolInstallHint -ErrorAction SilentlyContinue)) {
        $repoRoot = if (Get-Command Get-RepoRoot -ErrorAction SilentlyContinue) {
            Get-RepoRoot -ScriptPath $PSScriptRoot -ErrorAction SilentlyContinue
        }
        else {
            Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
        }
        
        if ($repoRoot) {
            $commandModulePath = Join-Path $repoRoot 'scripts' 'lib' 'utilities' 'Command.psm1'
            if (Test-Path -LiteralPath $commandModulePath) {
                Import-Module $commandModulePath -DisableNameChecking -ErrorAction SilentlyContinue
            }
        }
    }

    # ===============================================
    # Launch-Alacritty - Launch Alacritty terminal
    # ===============================================

    <#
    .SYNOPSIS
        Launches Alacritty terminal emulator.
    
    .DESCRIPTION
        Launches Alacritty, a fast, cross-platform terminal emulator.
        Optionally executes a command in the new terminal.
    
    .PARAMETER Command
        Command to execute in the new terminal.
    
    .PARAMETER WorkingDirectory
        Working directory for the new terminal.
    
    .EXAMPLE
        Launch-Alacritty
        
        Launches Alacritty terminal.
    
    .EXAMPLE
        Launch-Alacritty -Command "git status"
        
        Launches Alacritty and executes a command.
    
    .OUTPUTS
        None.
    #>
    function Launch-Alacritty {
        [CmdletBinding()]
        param(
            [string]$Command,
            
            [string]$WorkingDirectory
        )

        if (-not (Test-CachedCommand 'alacritty')) {
            $repoRoot = if (Get-Command Get-RepoRoot -ErrorAction SilentlyContinue) {
                Get-RepoRoot -ScriptPath $PSScriptRoot -ErrorAction SilentlyContinue
            }
            else {
                Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
            }
            $installHint = if (Get-Command Get-ToolInstallHint -ErrorAction SilentlyContinue) {
                Get-ToolInstallHint -ToolName 'alacritty' -RepoRoot $repoRoot
            }
            if (Get-Command Write-MissingToolWarning -ErrorAction SilentlyContinue) {
                Write-MissingToolWarning -Tool 'alacritty' -InstallHint $installHint
            }
            else {
                Write-Warning "alacritty is not installed. Install it with: scoop install alacritty"
            }
            return
        }

        $arguments = @()
        
        if ($WorkingDirectory) {
            if (-not (Test-Path -LiteralPath $WorkingDirectory)) {
                if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                    Write-StructuredError -ErrorRecord (New-Object System.Management.Automation.ErrorRecord(
                            [System.IO.DirectoryNotFoundException]::new("Working directory not found: $WorkingDirectory"),
                            'WorkingDirectoryNotFound',
                            [System.Management.Automation.ErrorCategory]::ObjectNotFound,
                            $WorkingDirectory
                        )) -OperationName 'terminal.alacritty.launch' -Context @{ working_directory = $WorkingDirectory }
                }
                else {
                    Write-Error "Working directory not found: $WorkingDirectory"
                }
                return
            }
            $arguments += '--working-directory', $WorkingDirectory
        }
        
        if ($Command) {
            $arguments += '-e', 'pwsh', '-NoExit', '-Command', $Command
        }

        if (Get-Command Invoke-WithWideEvent -ErrorAction SilentlyContinue) {
            Invoke-WithWideEvent -OperationName 'terminal.alacritty.launch' -Context @{
                working_directory = $WorkingDirectory
                has_command       = (-not [string]::IsNullOrWhiteSpace($Command))
            } -ScriptBlock {
                Start-Process -FilePath 'alacritty' -ArgumentList $arguments -ErrorAction Stop
            } | Out-Null
        }
        else {
            try {
                Start-Process -FilePath 'alacritty' -ArgumentList $arguments -ErrorAction Stop
            }
            catch {
                Write-Error "Failed to launch Alacritty: $($_.Exception.Message)"
            }
        }
    }

    # ===============================================
    # Launch-Kitty - Launch Kitty terminal
    # ===============================================

    <#
    .SYNOPSIS
        Launches Kitty terminal emulator.
    
    .DESCRIPTION
        Launches Kitty, a fast, feature-rich terminal emulator.
        Optionally executes a command in the new terminal.
    
    .PARAMETER Command
        Command to execute in the new terminal.
    
    .PARAMETER WorkingDirectory
        Working directory for the new terminal.
    
    .EXAMPLE
        Launch-Kitty
        
        Launches Kitty terminal.
    
    .EXAMPLE
        Launch-Kitty -Command "npm start"
        
        Launches Kitty and executes a command.
    
    .OUTPUTS
        None.
    #>
    function Launch-Kitty {
        [CmdletBinding()]
        param(
            [string]$Command,
            
            [string]$WorkingDirectory
        )

        if (-not (Test-CachedCommand 'kitty')) {
            $repoRoot = if (Get-Command Get-RepoRoot -ErrorAction SilentlyContinue) {
                Get-RepoRoot -ScriptPath $PSScriptRoot -ErrorAction SilentlyContinue
            }
            else {
                Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
            }
            $installHint = if (Get-Command Get-ToolInstallHint -ErrorAction SilentlyContinue) {
                Get-ToolInstallHint -ToolName 'kitty' -RepoRoot $repoRoot
            }
            if (Get-Command Write-MissingToolWarning -ErrorAction SilentlyContinue) {
                Write-MissingToolWarning -Tool 'kitty' -InstallHint $installHint
            }
            else {
                Write-Warning "kitty is not installed. Install it with: scoop install kitty"
            }
            return
        }

        $arguments = @()
        
        if ($WorkingDirectory) {
            if (-not (Test-Path -LiteralPath $WorkingDirectory)) {
                if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                    Write-StructuredError -ErrorRecord (New-Object System.Management.Automation.ErrorRecord(
                            [System.IO.DirectoryNotFoundException]::new("Working directory not found: $WorkingDirectory"),
                            'WorkingDirectoryNotFound',
                            [System.Management.Automation.ErrorCategory]::ObjectNotFound,
                            $WorkingDirectory
                        )) -OperationName 'terminal.kitty.launch' -Context @{ working_directory = $WorkingDirectory }
                }
                else {
                    Write-Error "Working directory not found: $WorkingDirectory"
                }
                return
            }
            $arguments += '--directory', $WorkingDirectory
        }
        
        if ($Command) {
            $arguments += 'pwsh', '-NoExit', '-Command', $Command
        }

        if (Get-Command Invoke-WithWideEvent -ErrorAction SilentlyContinue) {
            Invoke-WithWideEvent -OperationName 'terminal.kitty.launch' -Context @{
                working_directory = $WorkingDirectory
                has_command       = (-not [string]::IsNullOrWhiteSpace($Command))
            } -ScriptBlock {
                Start-Process -FilePath 'kitty' -ArgumentList $arguments -ErrorAction Stop
            } | Out-Null
        }
        else {
            try {
                Start-Process -FilePath 'kitty' -ArgumentList $arguments -ErrorAction Stop
            }
            catch {
                Write-Error "Failed to launch Kitty: $($_.Exception.Message)"
            }
        }
    }

    # ===============================================
    # Launch-WezTerm - Launch WezTerm terminal
    # ===============================================

    <#
    .SYNOPSIS
        Launches WezTerm terminal emulator.
    
    .DESCRIPTION
        Launches WezTerm, a GPU-accelerated cross-platform terminal emulator.
        Prefers wezterm-nightly, falls back to wezterm.
        Optionally executes a command in the new terminal.
    
    .PARAMETER Command
        Command to execute in the new terminal.
    
    .PARAMETER WorkingDirectory
        Working directory for the new terminal.
    
    .EXAMPLE
        Launch-WezTerm
        
        Launches WezTerm terminal.
    
    .EXAMPLE
        Launch-WezTerm -Command "docker ps"
        
        Launches WezTerm and executes a command.
    
    .OUTPUTS
        None.
    #>
    function Launch-WezTerm {
        [CmdletBinding()]
        param(
            [string]$Command,
            
            [string]$WorkingDirectory
        )

        # Prefer wezterm-nightly, fallback to wezterm
        $tool = $null
        if (Test-CachedCommand 'wezterm-nightly') {
            $tool = 'wezterm-nightly'
        }
        elseif (Test-CachedCommand 'wezterm') {
            $tool = 'wezterm'
        }

        if (-not $tool) {
            $repoRoot = if (Get-Command Get-RepoRoot -ErrorAction SilentlyContinue) {
                Get-RepoRoot -ScriptPath $PSScriptRoot -ErrorAction SilentlyContinue
            }
            else {
                Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
            }
            $installHint = if (Get-Command Get-ToolInstallHint -ErrorAction SilentlyContinue) {
                Get-ToolInstallHint -ToolName 'wezterm-nightly' -RepoRoot $repoRoot
            }
            if (Get-Command Write-MissingToolWarning -ErrorAction SilentlyContinue) {
                Write-MissingToolWarning -Tool 'wezterm-nightly' -InstallHint $installHint
            }
            else {
                Write-Warning "wezterm-nightly or wezterm is not installed. Install it with: scoop install wezterm-nightly"
            }
            return
        }

        $arguments = @()
        
        if ($WorkingDirectory) {
            if (-not (Test-Path -LiteralPath $WorkingDirectory)) {
                Write-Error "Working directory not found: $WorkingDirectory"
                return
            }
            $arguments += 'start', '--cwd', $WorkingDirectory
        }
        else {
            $arguments += 'start'
        }
        
        if ($Command) {
            $arguments += 'pwsh', '-NoExit', '-Command', $Command
        }

        try {
            Start-Process -FilePath $tool -ArgumentList $arguments -ErrorAction Stop
        }
        catch {
            Write-Error "Failed to launch WezTerm: $($_.Exception.Message)"
        }
    }

    # ===============================================
    # Launch-Tabby - Launch Tabby terminal
    # ===============================================

    <#
    .SYNOPSIS
        Launches Tabby terminal emulator.
    
    .DESCRIPTION
        Launches Tabby, a modern terminal emulator with SSH and serial port support.
        Optionally executes a command in the new terminal.
    
    .PARAMETER Command
        Command to execute in the new terminal.
    
    .PARAMETER WorkingDirectory
        Working directory for the new terminal.
    
    .EXAMPLE
        Launch-Tabby
        
        Launches Tabby terminal.
    
    .EXAMPLE
        Launch-Tabby -Command "npm run dev"
        
        Launches Tabby and executes a command.
    
    .OUTPUTS
        None.
    #>
    function Launch-Tabby {
        [CmdletBinding()]
        param(
            [string]$Command,
            
            [string]$WorkingDirectory
        )

        if (-not (Test-CachedCommand 'tabby')) {
            $repoRoot = if (Get-Command Get-RepoRoot -ErrorAction SilentlyContinue) {
                Get-RepoRoot -ScriptPath $PSScriptRoot -ErrorAction SilentlyContinue
            }
            else {
                Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
            }
            $installHint = if (Get-Command Get-ToolInstallHint -ErrorAction SilentlyContinue) {
                Get-ToolInstallHint -ToolName 'tabby' -RepoRoot $repoRoot
            }
            if (Get-Command Write-MissingToolWarning -ErrorAction SilentlyContinue) {
                Write-MissingToolWarning -Tool 'tabby' -InstallHint $installHint
            }
            else {
                Write-Warning "tabby is not installed. Install it with: scoop install tabby"
            }
            return
        }

        $arguments = @()
        
        if ($WorkingDirectory) {
            if (-not (Test-Path -LiteralPath $WorkingDirectory)) {
                Write-Error "Working directory not found: $WorkingDirectory"
                return
            }
            $arguments += '--cwd', $WorkingDirectory
        }
        
        if ($Command) {
            $arguments += 'pwsh', '-NoExit', '-Command', $Command
        }

        try {
            Start-Process -FilePath 'tabby' -ArgumentList $arguments -ErrorAction Stop
        }
        catch {
            Write-Error "Failed to launch Tabby: $($_.Exception.Message)"
        }
    }

    # ===============================================
    # Start-Tmux - Start tmux session
    # ===============================================

    <#
    .SYNOPSIS
        Starts a tmux terminal multiplexer session.
    
    .DESCRIPTION
        Starts a new tmux session or attaches to an existing one.
        Supports session naming and command execution.
    
    .PARAMETER SessionName
        Name for the tmux session. If not provided, creates a new session.
    
    .PARAMETER Command
        Command to execute in the new session.
    
    .PARAMETER Attach
        Attach to existing session if it exists, otherwise create new one.
    
    .EXAMPLE
        Start-Tmux
        
        Starts a new tmux session.
    
    .EXAMPLE
        Start-Tmux -SessionName "dev" -Command "npm start"
        
        Starts a named tmux session and executes a command.
    
    .EXAMPLE
        Start-Tmux -SessionName "dev" -Attach
        
        Attaches to existing session or creates new one.
    
    .OUTPUTS
        System.String. Session name or nothing.
    #>
    function Start-Tmux {
        [CmdletBinding()]
        [OutputType([string])]
        param(
            [string]$SessionName,
            
            [string]$Command,
            
            [switch]$Attach
        )

        if (-not (Test-CachedCommand 'tmux')) {
            $repoRoot = if (Get-Command Get-RepoRoot -ErrorAction SilentlyContinue) {
                Get-RepoRoot -ScriptPath $PSScriptRoot -ErrorAction SilentlyContinue
            }
            else {
                Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
            }
            $installHint = if (Get-Command Get-ToolInstallHint -ErrorAction SilentlyContinue) {
                Get-ToolInstallHint -ToolName 'tmux' -RepoRoot $repoRoot
            }
            if (Get-Command Write-MissingToolWarning -ErrorAction SilentlyContinue) {
                Write-MissingToolWarning -Tool 'tmux' -InstallHint $installHint
            }
            else {
                Write-Warning "tmux is not installed. Install it with: scoop install tmux"
            }
            return
        }

        try {
            if ($SessionName) {
                if ($Attach) {
                    # Check if session exists
                    $sessions = & tmux list-sessions -F '#{session_name}' 2>&1
                    if ($sessions -contains $SessionName) {
                        # Attach to existing session
                        & tmux attach-session -t $SessionName
                        return $SessionName
                    }
                }
                
                # Create new named session
                $arguments = @('new-session', '-d', '-s', $SessionName)
                
                if ($Command) {
                    $arguments += $Command
                }
                
                $output = & tmux $arguments 2>&1
                if ($LASTEXITCODE -eq 0) {
                    # Attach to the session
                    & tmux attach-session -t $SessionName
                    return $SessionName
                }
                else {
                    Write-Error "Failed to create tmux session. Exit code: $LASTEXITCODE"
                }
            }
            else {
                # Create new unnamed session
                $arguments = @('new-session', '-d')
                
                if ($Command) {
                    $arguments += $Command
                }
                
                $output = & tmux $arguments 2>&1
                if ($LASTEXITCODE -eq 0) {
                    # Attach to the session
                    & tmux attach-session
                }
                else {
                    Write-Error "Failed to create tmux session. Exit code: $LASTEXITCODE"
                }
            }
        }
        catch {
            Write-Error "Failed to start tmux: $($_.Exception.Message)"
        }
    }

    # ===============================================
    # Get-TerminalInfo - Get terminal information
    # ===============================================

    <#
    .SYNOPSIS
        Gets information about available terminal emulators.
    
    .DESCRIPTION
        Checks for installed terminal emulators and returns information about them.
        Lists available terminals and their status.
    
    .EXAMPLE
        Get-TerminalInfo
        
        Lists all available terminal emulators.
    
    .OUTPUTS
        System.Object[]. Array of terminal information objects.
    #>
    function Get-TerminalInfo {
        [CmdletBinding()]
        [OutputType([object[]])]
        param()

        $terminals = @()
        
        $terminalList = @{
            'Alacritty'        = @('alacritty')
            'Kitty'            = @('kitty')
            'WezTerm'          = @('wezterm-nightly', 'wezterm')
            'Tabby'            = @('tabby')
            'Windows Terminal' = @('wt', 'windows-terminal')
            'Hyper'            = @('hyper')
            'Terminator'       = @('terminator')
            'tmux'             = @('tmux')
            'screen'           = @('screen')
        }
        
        foreach ($terminalName in $terminalList.Keys) {
            $commands = $terminalList[$terminalName]
            $foundCommand = $null
            
            foreach ($cmd in $commands) {
                if (Test-CachedCommand $cmd) {
                    $foundCommand = $cmd
                    break
                }
            }
            
            if ($foundCommand) {
                $terminals += [PSCustomObject]@{
                    Name      = $terminalName
                    Command   = $foundCommand
                    Available = $true
                }
            }
        }
        
        return $terminals
    }

    # Register functions
    if (Get-Command -Name 'Set-AgentModeFunction' -ErrorAction SilentlyContinue) {
        Set-AgentModeFunction -Name 'Launch-Alacritty' -Body ${function:Launch-Alacritty}
        Set-AgentModeFunction -Name 'Launch-Kitty' -Body ${function:Launch-Kitty}
        Set-AgentModeFunction -Name 'Launch-WezTerm' -Body ${function:Launch-WezTerm}
        Set-AgentModeFunction -Name 'Launch-Tabby' -Body ${function:Launch-Tabby}
        Set-AgentModeFunction -Name 'Start-Tmux' -Body ${function:Start-Tmux}
        Set-AgentModeFunction -Name 'Get-TerminalInfo' -Body ${function:Get-TerminalInfo}
    }

    # Mark fragment as loaded
    if (Get-Command Set-FragmentLoaded -ErrorAction SilentlyContinue) {
        Set-FragmentLoaded -FragmentName 'terminal-enhanced'
    }
}
catch {
    if ($env:PS_PROFILE_DEBUG) {
        if (Get-Command Write-ProfileError -ErrorAction SilentlyContinue) {
            Write-ProfileError -ErrorRecord $_ -Context "Fragment: terminal-enhanced" -Category 'Fragment'
        }
        else {
            Write-Warning "Failed to load terminal-enhanced fragment: $($_.Exception.Message)"
        }
    }
}

