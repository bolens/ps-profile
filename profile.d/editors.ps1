# ===============================================
# editors.ps1
# Editor and IDE integrations
# ===============================================
# Tier: optional
# Dependencies: bootstrap, env

<#
.SYNOPSIS
    Editor and IDE integrations fragment.

.DESCRIPTION
    Provides wrapper functions for code editors and IDEs:
    - VS Code: Visual Studio Code, VS Code Insiders, VS Codium
    - Modern Editors: Cursor, Lapce, Zed
    - Vim-based: Neovim, Vim, GoNeovim
    - Classic: Emacs, Micro
    - IDEs: Light Table, Theia IDE

.NOTES
    All functions gracefully degrade when tools are not installed.
    This module provides editor and IDE launching capabilities.
#>

try {
    # Idempotency check: skip if already loaded
    if (Get-Command Test-FragmentLoaded -ErrorAction SilentlyContinue) {
        if (Test-FragmentLoaded -FragmentName 'editors') { return }
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
    # Edit-WithVSCode - Open in VS Code
    # ===============================================

    <#
    .SYNOPSIS
        Opens files or directories in Visual Studio Code.
    
    .DESCRIPTION
        Opens files or directories in VS Code. Prefers vscode-insiders, falls back to vscode or vscodium.
        Optionally opens in a new window.
    
    .PARAMETER Path
        File or directory path to open. Defaults to current directory.
    
    .PARAMETER NewWindow
        Open in a new window.
    
    .PARAMETER Wait
        Wait for the editor to close before returning.
    
    .EXAMPLE
        Edit-WithVSCode
        
        Opens current directory in VS Code.
    
    .EXAMPLE
        Edit-WithVSCode -Path "C:\Projects\MyApp"
        
        Opens a directory in VS Code.
    
    .EXAMPLE
        Edit-WithVSCode -Path "script.ps1" -NewWindow
        
        Opens a file in a new VS Code window.
    
    .OUTPUTS
        None.
    #>
    function Edit-WithVSCode {
        [CmdletBinding()]
        param(
            [string]$Path = (Get-Location).Path,
            
            [switch]$NewWindow,
            
            [switch]$Wait
        )

        # Prefer vscode-insiders, fallback to vscode, then vscodium
        $tool = $null
        if (Test-CachedCommand 'code-insiders') {
            $tool = 'code-insiders'
        }
        elseif (Test-CachedCommand 'code') {
            $tool = 'code'
        }
        elseif (Test-CachedCommand 'codium') {
            $tool = 'codium'
        }

        if (-not $tool) {
            $repoRoot = if (Get-Command Get-RepoRoot -ErrorAction SilentlyContinue) {
                Get-RepoRoot -ScriptPath $PSScriptRoot -ErrorAction SilentlyContinue
            }
            else {
                Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
            }
            $installHint = if (Get-Command Get-ToolInstallHint -ErrorAction SilentlyContinue) {
                Get-ToolInstallHint -ToolName 'vscode' -RepoRoot $repoRoot
            }
            if (Get-Command Write-MissingToolWarning -ErrorAction SilentlyContinue) {
                Write-MissingToolWarning -Tool 'vscode' -InstallHint $installHint
            }
            else {
                Write-Warning "vscode, vscode-insiders, or vscodium is not installed. Install it with: scoop install vscode"
            }
            return
        }

        if (-not (Test-Path -LiteralPath $Path)) {
            if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                Write-StructuredError -ErrorRecord (New-Object System.Management.Automation.ErrorRecord(
                        [System.IO.PathNotFoundException]::new("Path not found: $Path"),
                        'PathNotFound',
                        [System.Management.Automation.ErrorCategory]::ObjectNotFound,
                        $Path
                    )) -OperationName 'editor.vscode.open' -Context @{ path = $Path }
            }
            else {
                Write-Error "Path not found: $Path"
            }
            return
        }

        $arguments = @()
        
        if ($NewWindow) {
            $arguments += '--new-window'
        }
        
        if ($Wait) {
            $arguments += '--wait'
        }
        
        $arguments += $Path

        if (Get-Command Invoke-WithWideEvent -ErrorAction SilentlyContinue) {
            Invoke-WithWideEvent -OperationName 'editor.vscode.open' -Context @{
                path       = $Path
                new_window = $NewWindow.IsPresent
                wait       = $Wait.IsPresent
            } -ScriptBlock {
                if ($Wait) {
                    $process = Start-Process -FilePath $tool -ArgumentList $arguments -Wait -PassThru -ErrorAction Stop
                    if ($process.ExitCode -ne 0) {
                        Write-Warning "VS Code exited with code: $($process.ExitCode)"
                    }
                }
                else {
                    Start-Process -FilePath $tool -ArgumentList $arguments -ErrorAction Stop
                }
            } | Out-Null
        }
        else {
            try {
                if ($Wait) {
                    $process = Start-Process -FilePath $tool -ArgumentList $arguments -Wait -PassThru -ErrorAction Stop
                    if ($process.ExitCode -ne 0) {
                        Write-Warning "VS Code exited with code: $($process.ExitCode)"
                    }
                }
                else {
                    Start-Process -FilePath $tool -ArgumentList $arguments -ErrorAction Stop
                }
            }
            catch {
                Write-Error "Failed to launch VS Code: $($_.Exception.Message)"
            }
        }
    }

    # ===============================================
    # Edit-WithCursor - Open in Cursor
    # ===============================================

    <#
    .SYNOPSIS
        Opens files or directories in Cursor editor.
    
    .DESCRIPTION
        Opens files or directories in Cursor, an AI-powered code editor.
        Optionally opens in a new window.
    
    .PARAMETER Path
        File or directory path to open. Defaults to current directory.
    
    .PARAMETER NewWindow
        Open in a new window.
    
    .EXAMPLE
        Edit-WithCursor
        
        Opens current directory in Cursor.
    
    .EXAMPLE
        Edit-WithCursor -Path "C:\Projects\MyApp"
        
        Opens a directory in Cursor.
    
    .OUTPUTS
        None.
    #>
    function Edit-WithCursor {
        [CmdletBinding()]
        param(
            [string]$Path = (Get-Location).Path,
            
            [switch]$NewWindow
        )

        if (-not (Test-CachedCommand 'cursor')) {
            $repoRoot = if (Get-Command Get-RepoRoot -ErrorAction SilentlyContinue) {
                Get-RepoRoot -ScriptPath $PSScriptRoot -ErrorAction SilentlyContinue
            }
            else {
                Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
            }
            $installHint = if (Get-Command Get-ToolInstallHint -ErrorAction SilentlyContinue) {
                Get-ToolInstallHint -ToolName 'cursor' -RepoRoot $repoRoot
            }
            if (Get-Command Write-MissingToolWarning -ErrorAction SilentlyContinue) {
                Write-MissingToolWarning -Tool 'cursor' -InstallHint $installHint
            }
            else {
                Write-Warning "cursor is not installed. Install it with: scoop install cursor"
            }
            return
        }

        if (-not (Test-Path -LiteralPath $Path)) {
            if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                Write-StructuredError -ErrorRecord (New-Object System.Management.Automation.ErrorRecord(
                        [System.IO.PathNotFoundException]::new("Path not found: $Path"),
                        'PathNotFound',
                        [System.Management.Automation.ErrorCategory]::ObjectNotFound,
                        $Path
                    )) -OperationName 'editor.cursor.open' -Context @{ path = $Path }
            }
            else {
                Write-Error "Path not found: $Path"
            }
            return
        }

        $arguments = @()
        
        if ($NewWindow) {
            $arguments += '--new-window'
        }
        
        $arguments += $Path

        if (Get-Command Invoke-WithWideEvent -ErrorAction SilentlyContinue) {
            Invoke-WithWideEvent -OperationName 'editor.cursor.open' -Context @{
                path       = $Path
                new_window = $NewWindow.IsPresent
            } -ScriptBlock {
                Start-Process -FilePath 'cursor' -ArgumentList $arguments -ErrorAction Stop
            } | Out-Null
        }
        else {
            try {
                Start-Process -FilePath 'cursor' -ArgumentList $arguments -ErrorAction Stop
            }
            catch {
                Write-Error "Failed to launch Cursor: $($_.Exception.Message)"
            }
        }
    }

    # ===============================================
    # Edit-WithNeovim - Open in Neovim
    # ===============================================

    <#
    .SYNOPSIS
        Opens files in Neovim editor.
    
    .DESCRIPTION
        Opens files in Neovim. Prefers neovim-nightly, falls back to neovim.
        Can use GUI version (neovim-qt) if available.
    
    .PARAMETER Path
        File path to open. Defaults to current directory.
    
    .PARAMETER UseGui
        Use GUI version (neovim-qt) if available.
    
    .EXAMPLE
        Edit-WithNeovim
        
        Opens Neovim in current directory.
    
    .EXAMPLE
        Edit-WithNeovim -Path "script.ps1"
        
        Opens a file in Neovim.
    
    .EXAMPLE
        Edit-WithNeovim -Path "script.ps1" -UseGui
        
        Opens a file in Neovim GUI.
    
    .OUTPUTS
        None.
    #>
    function Edit-WithNeovim {
        [CmdletBinding()]
        param(
            [string]$Path = (Get-Location).Path,
            
            [switch]$UseGui
        )

        # Determine which tool to use
        $tool = $null
        if ($UseGui) {
            if (Test-CachedCommand 'neovim-qt') {
                $tool = 'neovim-qt'
            }
            elseif (Test-CachedCommand 'nvim-qt') {
                $tool = 'nvim-qt'
            }
        }
        
        if (-not $tool) {
            # Prefer neovim-nightly, fallback to neovim or nvim
            if (Test-CachedCommand 'neovim-nightly') {
                $tool = 'neovim-nightly'
            }
            elseif (Test-CachedCommand 'nvim') {
                $tool = 'nvim'
            }
            elseif (Test-CachedCommand 'neovim') {
                $tool = 'neovim'
            }
        }

        if (-not $tool) {
            $repoRoot = if (Get-Command Get-RepoRoot -ErrorAction SilentlyContinue) {
                Get-RepoRoot -ScriptPath $PSScriptRoot -ErrorAction SilentlyContinue
            }
            else {
                Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
            }
            $installHint = if (Get-Command Get-ToolInstallHint -ErrorAction SilentlyContinue) {
                Get-ToolInstallHint -ToolName 'neovim-nightly' -RepoRoot $repoRoot
            }
            if (Get-Command Write-MissingToolWarning -ErrorAction SilentlyContinue) {
                Write-MissingToolWarning -Tool 'neovim-nightly' -InstallHint $installHint
            }
            else {
                Write-Warning "neovim-nightly, nvim, or neovim is not installed. Install it with: scoop install neovim-nightly"
            }
            return
        }

        if (-not (Test-Path -LiteralPath $Path)) {
            Write-Error "Path not found: $Path"
            return
        }

        $arguments = @($Path)

        try {
            Start-Process -FilePath $tool -ArgumentList $arguments -ErrorAction Stop
        }
        catch {
            Write-Error "Failed to launch Neovim: $($_.Exception.Message)"
        }
    }

    # ===============================================
    # Launch-Emacs - Launch Emacs
    # ===============================================

    <#
    .SYNOPSIS
        Launches Emacs editor.
    
    .DESCRIPTION
        Launches Emacs editor. Optionally opens files.
    
    .PARAMETER Path
        File path to open. Defaults to current directory.
    
    .PARAMETER NoWindow
        Start Emacs in daemon mode (no window).
    
    .EXAMPLE
        Launch-Emacs
        
        Launches Emacs.
    
    .EXAMPLE
        Launch-Emacs -Path "script.ps1"
        
        Opens a file in Emacs.
    
    .OUTPUTS
        None.
    #>
    function Launch-Emacs {
        [CmdletBinding()]
        param(
            [string]$Path,
            
            [switch]$NoWindow
        )

        if (-not (Test-CachedCommand 'emacs')) {
            $repoRoot = if (Get-Command Get-RepoRoot -ErrorAction SilentlyContinue) {
                Get-RepoRoot -ScriptPath $PSScriptRoot -ErrorAction SilentlyContinue
            }
            else {
                Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
            }
            $installHint = if (Get-Command Get-ToolInstallHint -ErrorAction SilentlyContinue) {
                Get-ToolInstallHint -ToolName 'emacs' -RepoRoot $repoRoot
            }
            if (Get-Command Write-MissingToolWarning -ErrorAction SilentlyContinue) {
                Write-MissingToolWarning -Tool 'emacs' -InstallHint $installHint
            }
            else {
                Write-Warning "emacs is not installed. Install it with: scoop install emacs"
            }
            return
        }

        $arguments = @()
        
        if ($NoWindow) {
            $arguments += '--daemon'
        }
        
        if ($Path) {
            if (-not (Test-Path -LiteralPath $Path)) {
                Write-Error "Path not found: $Path"
                return
            }
            $arguments += $Path
        }

        try {
            Start-Process -FilePath 'emacs' -ArgumentList $arguments -ErrorAction Stop
        }
        catch {
            Write-Error "Failed to launch Emacs: $($_.Exception.Message)"
        }
    }

    # ===============================================
    # Launch-Lapce - Launch Lapce
    # ===============================================

    <#
    .SYNOPSIS
        Launches Lapce editor.
    
    .DESCRIPTION
        Launches Lapce, a fast code editor. Prefers lapce-nightly, falls back to lapce.
        Optionally opens files or directories.
    
    .PARAMETER Path
        File or directory path to open. Defaults to current directory.
    
    .EXAMPLE
        Launch-Lapce
        
        Launches Lapce.
    
    .EXAMPLE
        Launch-Lapce -Path "C:\Projects\MyApp"
        
        Opens a directory in Lapce.
    
    .OUTPUTS
        None.
    #>
    function Launch-Lapce {
        [CmdletBinding()]
        param(
            [string]$Path = (Get-Location).Path
        )

        # Prefer lapce-nightly, fallback to lapce
        $tool = $null
        if (Test-CachedCommand 'lapce-nightly') {
            $tool = 'lapce-nightly'
        }
        elseif (Test-CachedCommand 'lapce') {
            $tool = 'lapce'
        }

        if (-not $tool) {
            $repoRoot = if (Get-Command Get-RepoRoot -ErrorAction SilentlyContinue) {
                Get-RepoRoot -ScriptPath $PSScriptRoot -ErrorAction SilentlyContinue
            }
            else {
                Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
            }
            $installHint = if (Get-Command Get-ToolInstallHint -ErrorAction SilentlyContinue) {
                Get-ToolInstallHint -ToolName 'lapce-nightly' -RepoRoot $repoRoot
            }
            if (Get-Command Write-MissingToolWarning -ErrorAction SilentlyContinue) {
                Write-MissingToolWarning -Tool 'lapce-nightly' -InstallHint $installHint
            }
            else {
                Write-Warning "lapce-nightly or lapce is not installed. Install it with: scoop install lapce-nightly"
            }
            return
        }

        if (-not (Test-Path -LiteralPath $Path)) {
            Write-Error "Path not found: $Path"
            return
        }

        $arguments = @($Path)

        try {
            Start-Process -FilePath $tool -ArgumentList $arguments -ErrorAction Stop
        }
        catch {
            Write-Error "Failed to launch Lapce: $($_.Exception.Message)"
        }
    }

    # ===============================================
    # Launch-Zed - Launch Zed
    # ===============================================

    <#
    .SYNOPSIS
        Launches Zed editor.
    
    .DESCRIPTION
        Launches Zed, a high-performance code editor. Prefers zed-nightly, falls back to zed.
        Optionally opens files or directories.
    
    .PARAMETER Path
        File or directory path to open. Defaults to current directory.
    
    .EXAMPLE
        Launch-Zed
        
        Launches Zed.
    
    .EXAMPLE
        Launch-Zed -Path "C:\Projects\MyApp"
        
        Opens a directory in Zed.
    
    .OUTPUTS
        None.
    #>
    function Launch-Zed {
        [CmdletBinding()]
        param(
            [string]$Path = (Get-Location).Path
        )

        # Prefer zed-nightly, fallback to zed
        $tool = $null
        if (Test-CachedCommand 'zed-nightly') {
            $tool = 'zed-nightly'
        }
        elseif (Test-CachedCommand 'zed') {
            $tool = 'zed'
        }

        if (-not $tool) {
            $repoRoot = if (Get-Command Get-RepoRoot -ErrorAction SilentlyContinue) {
                Get-RepoRoot -ScriptPath $PSScriptRoot -ErrorAction SilentlyContinue
            }
            else {
                Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
            }
            $installHint = if (Get-Command Get-ToolInstallHint -ErrorAction SilentlyContinue) {
                Get-ToolInstallHint -ToolName 'zed-nightly' -RepoRoot $repoRoot
            }
            if (Get-Command Write-MissingToolWarning -ErrorAction SilentlyContinue) {
                Write-MissingToolWarning -Tool 'zed-nightly' -InstallHint $installHint
            }
            else {
                Write-Warning "zed-nightly or zed is not installed. Install it with: scoop install zed-nightly"
            }
            return
        }

        if (-not (Test-Path -LiteralPath $Path)) {
            Write-Error "Path not found: $Path"
            return
        }

        $arguments = @($Path)

        try {
            Start-Process -FilePath $tool -ArgumentList $arguments -ErrorAction Stop
        }
        catch {
            Write-Error "Failed to launch Zed: $($_.Exception.Message)"
        }
    }

    # ===============================================
    # Get-EditorInfo - Get editor information
    # ===============================================

    <#
    .SYNOPSIS
        Gets information about available editors.
    
    .DESCRIPTION
        Checks for installed editors and returns information about them.
        Lists available editors and their status.
    
    .EXAMPLE
        Get-EditorInfo
        
        Lists all available editors.
    
    .OUTPUTS
        System.Object[]. Array of editor information objects.
    #>
    function Get-EditorInfo {
        [CmdletBinding()]
        [OutputType([object[]])]
        param()

        $editors = @()
        
        $editorList = @{
            'VS Code'     = @('code-insiders', 'code', 'codium')
            'Cursor'      = @('cursor')
            'Neovim'      = @('neovim-nightly', 'nvim', 'neovim')
            'Neovim Qt'   = @('neovim-qt', 'nvim-qt')
            'Vim'         = @('vim-nightly', 'vim')
            'Emacs'       = @('emacs')
            'Lapce'       = @('lapce-nightly', 'lapce')
            'Zed'         = @('zed-nightly', 'zed')
            'GoNeovim'    = @('goneovim-nightly', 'goneovim')
            'Micro'       = @('micro-nightly', 'micro')
            'Light Table' = @('lighttable')
            'Theia IDE'   = @('theia-ide')
        }
        
        foreach ($editorName in $editorList.Keys) {
            $commands = $editorList[$editorName]
            $foundCommand = $null
            
            foreach ($cmd in $commands) {
                if (Test-CachedCommand $cmd) {
                    $foundCommand = $cmd
                    break
                }
            }
            
            if ($foundCommand) {
                $editors += [PSCustomObject]@{
                    Name      = $editorName
                    Command   = $foundCommand
                    Available = $true
                }
            }
        }
        
        return $editors
    }

    # Register functions
    if (Get-Command -Name 'Set-AgentModeFunction' -ErrorAction SilentlyContinue) {
        Set-AgentModeFunction -Name 'Edit-WithVSCode' -Body ${function:Edit-WithVSCode}
        Set-AgentModeFunction -Name 'Edit-WithCursor' -Body ${function:Edit-WithCursor}
        Set-AgentModeFunction -Name 'Edit-WithNeovim' -Body ${function:Edit-WithNeovim}
        Set-AgentModeFunction -Name 'Launch-Emacs' -Body ${function:Launch-Emacs}
        Set-AgentModeFunction -Name 'Launch-Lapce' -Body ${function:Launch-Lapce}
        Set-AgentModeFunction -Name 'Launch-Zed' -Body ${function:Launch-Zed}
        Set-AgentModeFunction -Name 'Get-EditorInfo' -Body ${function:Get-EditorInfo}
    }

    # Mark fragment as loaded
    if (Get-Command Set-FragmentLoaded -ErrorAction SilentlyContinue) {
        Set-FragmentLoaded -FragmentName 'editors'
    }
}
catch {
    if ($env:PS_PROFILE_DEBUG) {
        if (Get-Command Write-ProfileError -ErrorAction SilentlyContinue) {
            Write-ProfileError -ErrorRecord $_ -Context "Fragment: editors" -Category 'Fragment'
        }
        else {
            Write-Warning "Failed to load editors fragment: $($_.Exception.Message)"
        }
    }
}

