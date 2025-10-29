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
    function vsc {
        [CmdletBinding()] param()
        # Runtime check: prefer Test-CachedCommand if available to avoid Get-Command cost
        if (Get-Command -Name Test-CachedCommand -ErrorAction SilentlyContinue) {
            if (Test-CachedCommand code) { code . } else { Write-Warning 'code (VS Code) not found in PATH' }
        }
        else {
            if (Test-Path Function:code -ErrorAction SilentlyContinue -or (Get-Command -Name code -ErrorAction SilentlyContinue)) { code . } else { Write-Warning 'code (VS Code) not found in PATH' }
        }
    }
}

# Open file in editor quickly
if (-not (Test-Path Function:e)) { function e { param($p) if (-not $p) { Write-Warning 'Usage: e <path>'; return } if (Get-Command -Name Test-CachedCommand -ErrorAction SilentlyContinue) { if (Test-CachedCommand code) { code $p } else { Write-Warning 'code (VS Code) not found in PATH' } } else { code $p } } }

# Jump to project root (uses git if available)
if (-not (Test-Path Function:project-root)) {
    <#
    .SYNOPSIS
        Changes to project root directory.
    .DESCRIPTION
        Changes the current directory to the root of the git repository if inside a git repo.
    #>
    function project-root {
        $root = (& git rev-parse --show-toplevel) 2>$null
        if ($LASTEXITCODE -eq 0 -and $root) { Set-Location -LiteralPath $root } else { Write-Warning 'Not inside a git repository' }
    }
}

























