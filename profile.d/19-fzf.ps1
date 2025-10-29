# ===============================================
# 19-fzf.ps1
# Lightweight fzf helpers (safe, idempotent)
# ===============================================

<#
17-fzf.ps1
Register lightweight fzf helpers but avoid probing for `fzf` at dot-source.
We register idempotent stubs that perform a runtime availability check when invoked.
#>

# ff: fuzzy-find files by name
if (-not (Test-Path Function:ff -ErrorAction SilentlyContinue)) {
    if (Test-Path Function:Test-CachedCommand -ErrorAction SilentlyContinue) {
        Set-Item -Path Function:ff -Value { param([string]$pattern = '') if (Test-CachedCommand fzf) { Get-ChildItem -Recurse -File | Where-Object { $_.Name -match $pattern } | fzf } else { Write-Warning 'fzf not found' } } -Force | Out-Null
    }
    else {
        Set-Item -Path Function:ff -Value { param([string]$pattern = '') if (Get-Command fzf -ErrorAction SilentlyContinue) { Get-ChildItem -Recurse -File | Where-Object { $_.Name -match $pattern } | fzf } else { Write-Warning 'fzf not found' } } -Force | Out-Null
    }
}

# fcmd: fuzzy-find a command
if (-not (Test-Path Function:fcmd -ErrorAction SilentlyContinue)) {
    if (Test-Path Function:Test-CachedCommand -ErrorAction SilentlyContinue) {
        Set-Item -Path Function:fcmd -Value { if (Test-CachedCommand fzf) { Get-Command | Out-String | fzf } else { Write-Warning 'fzf not found' } } -Force | Out-Null
    }
    else {
        Set-Item -Path Function:fcmd -Value { if (Get-Command fzf -ErrorAction SilentlyContinue) { Get-Command | Out-String | fzf } else { Write-Warning 'fzf not found' } } -Force | Out-Null
    }
}












