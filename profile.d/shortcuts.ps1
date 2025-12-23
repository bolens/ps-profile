# ===============================================
# shortcuts.ps1
# Small interactive shortcuts (editor, quick navigation, misc)
# ===============================================

# Helper function to find the best available editor
# Tier: essential
# Dependencies: bootstrap, env
function Get-AvailableEditor {
    <#
    .SYNOPSIS
        Finds the best available editor from a list of common editors.
    .DESCRIPTION
        Checks for installed editors in order of preference and returns the first available one.
    #>
    $editors = @(
        @{ Name = 'code'; DisplayName = 'VS Code' },
        @{ Name = 'code-insiders'; DisplayName = 'VS Code Insiders' },
        @{ Name = 'codium'; DisplayName = 'VSCodium' },
        @{ Name = 'nvim'; DisplayName = 'Neovim' },
        @{ Name = 'vim'; DisplayName = 'Vim' },
        @{ Name = 'emacs'; DisplayName = 'Emacs' },
        @{ Name = 'micro'; DisplayName = 'Micro' },
        @{ Name = 'nano'; DisplayName = 'Nano' },
        @{ Name = 'notepad++'; DisplayName = 'Notepad++' },
        @{ Name = 'sublime_text'; DisplayName = 'Sublime Text' },
        @{ Name = 'atom'; DisplayName = 'Atom' },
        @{ Name = 'gedit'; DisplayName = 'Gedit' },
        @{ Name = 'kate'; DisplayName = 'Kate' },
        @{ Name = 'leafpad'; DisplayName = 'Leafpad' },
        @{ Name = 'mousepad'; DisplayName = 'Mousepad' },
        @{ Name = 'xedit'; DisplayName = 'Xed' },
        @{ Name = 'notepad'; DisplayName = 'Notepad' }
    )

    foreach ($editor in $editors) {
        if (Test-CachedCommand $editor.Name) {
            return @{
                Command     = $editor.Name
                DisplayName = $editor.DisplayName
            }
        }
    }

    return $null
}

# Open current folder in editor (safe alias)
if (-not (Test-Path Function:vsc)) {
    <#
    .SYNOPSIS
        Opens current directory in the best available editor.
    .DESCRIPTION
        Launches the best available editor in the current directory.
    #>
    function Open-VSCode {
        [CmdletBinding()] param()
        try {
            $editor = Get-AvailableEditor
            if ($editor) {
                $currentPath = Get-Location
                try {
                    & $editor.Command $currentPath.Path 2>&1 | Out-Null
                    if ($LASTEXITCODE -ne 0 -and $LASTEXITCODE -ne $null) {
                        throw "Editor command failed with exit code $LASTEXITCODE"
                    }
                    Write-Verbose "Opened current directory in $($editor.DisplayName)"
                }
                catch {
                    Write-Error "Failed to execute $($editor.DisplayName) ($($editor.Command)): $($_.Exception.Message)"
                    throw
                }
            }
            else {
                Write-Warning 'No supported editor found in PATH. Install VS Code, VSCodium, Neovim, Vim, Emacs, Micro, or Nano.'
            }
        }
        catch {
            Write-Error "Failed to open editor: $($_.Exception.Message)"
            throw
        }
    }
    Set-Alias -Name vsc -Value Open-VSCode -ErrorAction SilentlyContinue
    Set-Alias -Name code -Value Open-VSCode -ErrorAction SilentlyContinue
}

# Open file in editor quickly
<#
.SYNOPSIS
    Opens file in the best available editor.
.DESCRIPTION
    Opens the specified file in the best available editor.
.PARAMETER p
    The path to the file to open.
#>
if (-not (Test-Path Function:Open-Editor)) {
    function Open-Editor {
        param($p)
        if (-not $p) { 
            Write-Warning 'Usage: Open-Editor <path>'
            return 
        }
        
        # Validate path exists
        if (-not ($p -and -not [string]::IsNullOrWhiteSpace($p) -and (Test-Path -LiteralPath $p -ErrorAction SilentlyContinue))) {
            Write-Error "Path not found: $p"
            return
        }
        
        try {
            $editor = Get-AvailableEditor
            if ($editor) {
                $resolvedPath = Resolve-Path $p -ErrorAction Stop | Select-Object -ExpandProperty Path
                try {
                    & $editor.Command $resolvedPath 2>&1 | Out-Null
                    if ($LASTEXITCODE -ne 0 -and $LASTEXITCODE -ne $null) {
                        throw "Editor command failed with exit code $LASTEXITCODE"
                    }
                    Write-Verbose "Opened '$resolvedPath' in $($editor.DisplayName)"
                }
                catch {
                    Write-Error "Failed to execute $($editor.DisplayName) ($($editor.Command)): $($_.Exception.Message)"
                    throw
                }
            }
            else {
                Write-Warning 'No supported editor found in PATH. Install VS Code, VSCodium, Neovim, Vim, Emacs, Micro, or Nano.'
            }
        }
        catch {
            Write-Error "Failed to open file in editor: $($_.Exception.Message)"
            throw
        }
    }
}
# Always set the alias, even if Open-Editor already exists (e.g., from mocks)
if (-not (Get-Alias e -ErrorAction SilentlyContinue)) {
    Set-Alias -Name e -Value Open-Editor -ErrorAction SilentlyContinue
}

# Jump to project root (uses git if available)
if (-not (Test-Path Function:project-root)) {
    <#
    .SYNOPSIS
        Changes to project root directory.
    .DESCRIPTION
        Changes the current directory to the root of the git repository if inside a git repo.
    #>
    function Get-ProjectRoot {
        try {
            # Check if git is available
            if (-not (Test-CachedCommand git)) {
                Write-MissingToolWarning -Tool 'git' -InstallHint 'Install git to use this function.'
                return
            }
            
            $root = (& git rev-parse --show-toplevel 2>&1)
            $exitCode = $LASTEXITCODE
            
            if ($exitCode -eq 0 -and $root -and $root.Trim()) {
                try {
                    Set-Location -LiteralPath $root.Trim() -ErrorAction Stop
                    Write-Verbose "Changed to project root: $root"
                }
                catch {
                    Write-Error "Failed to change to project root '$root': $($_.Exception.Message)"
                    throw
                }
            }
            else {
                $errorMsg = if ($root) { $root -join "`n" } else { "git rev-parse failed" }
                Write-Warning "Not inside a git repository or git command failed: $errorMsg"
            }
        }
        catch {
            Write-Error "Failed to find project root: $($_.Exception.Message)"
            throw
        }
    }
    Set-Alias -Name project-root -Value Get-ProjectRoot -ErrorAction SilentlyContinue
}
