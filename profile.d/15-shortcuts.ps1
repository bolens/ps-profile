# ===============================================
# 15-shortcuts.ps1
# Small interactive shortcuts (editor, quick navigation, misc)
# ===============================================

# Open current folder in VS Code (safe alias)
if (-not (Test-Path Function:vsc)) {
  function vsc {
    [CmdletBinding()] param()
    # Runtime check: prefer Test-CachedCommand if available to avoid Get-Command cost
    if (Get-Command -Name Test-CachedCommand -ErrorAction SilentlyContinue) {
      if (Test-CachedCommand code) { code . } else { Write-Warning 'code (VS Code) not found in PATH' }
    } else {
      if (Test-Path Function:code -ErrorAction SilentlyContinue -or (Get-Command -Name code -ErrorAction SilentlyContinue)) { code . } else { Write-Warning 'code (VS Code) not found in PATH' }
    }
  }
}

# Open file in editor quickly
if (-not (Test-Path Function:e)) { function e { param($p) if (-not $p) { Write-Warning 'Usage: e <path>'; return } if (Get-Command -Name Test-CachedCommand -ErrorAction SilentlyContinue) { if (Test-CachedCommand code) { code $p } else { Write-Warning 'code (VS Code) not found in PATH' } } else { code $p } } }

# Jump to project root (uses git if available)
if (-not (Test-Path Function:project-root)) {
  function project-root {
    $root = (& git rev-parse --show-toplevel) 2>$null
    if ($LASTEXITCODE -eq 0 -and $root) { Set-Location -LiteralPath $root } else { Write-Warning 'Not inside a git repository' }
  }
}







