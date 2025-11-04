# ===============================================
# 15-shortcuts.ps1
# Small interactive shortcuts (editor, quick navigation, misc)
# ===============================================

# Open current folder in VS Code (safe alias)
if (-not (Test-Path Function:vsc)) {
    <#
    .SYNOPSIS
        Opens current directory in VS Code.
    .DESCRIPTION
        Launches VS Code in the current directory if VS Code is available.
    #>
    function Open-VSCode {
        [CmdletBinding()] param()
        try {
            # Runtime check: prefer Test-CachedCommand if available to avoid Get-Command cost
            if (Get-Command -Name Test-CachedCommand -ErrorAction SilentlyContinue) {
                if (Test-CachedCommand code) { code . } else { Write-Warning 'code (VS Code) not found in PATH' }
            }
            else {
                if (Test-Path Function:code -ErrorAction SilentlyContinue -or (Get-Command -Name code -ErrorAction SilentlyContinue)) { code . } else { Write-Warning 'code (VS Code) not found in PATH' }
            }
        }
        catch {
            Write-Warning "Failed to open VS Code: $_"
        }
    }
    Set-Alias -Name vsc -Value Open-VSCode -ErrorAction SilentlyContinue
}

# Open file in editor quickly
<#
.SYNOPSIS
    Opens file in editor quickly.
.DESCRIPTION
    Opens the specified file in VS Code if available.
.PARAMETER p
    The path to the file to open.
#>
if (-not (Test-Path Function:Open-Editor)) {
    function Open-Editor {
        param($p)
        if (-not $p) { Write-Warning 'Usage: Open-Editor <path>'; return }
        try {
            if (Get-Command -Name Test-CachedCommand -ErrorAction SilentlyContinue) {
                if (Test-CachedCommand code) { code $p } else { Write-Warning 'code (VS Code) not found in PATH' }
            }
            else {
                code $p
            }
        }
        catch {
            Write-Warning "Failed to open file in editor: $_"
        }
    }
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
            $root = (& git rev-parse --show-toplevel) 2>$null
            if ($LASTEXITCODE -eq 0 -and $root) { Set-Location -LiteralPath $root } else { Write-Warning 'Not inside a git repository' }
        }
        catch {
            Write-Warning "Failed to find project root: $_"
        }
    }
    Set-Alias -Name project-root -Value Get-ProjectRoot -ErrorAction SilentlyContinue
}
