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
if (-not (Test-Path Function:Find-FileFuzzy -ErrorAction SilentlyContinue)) {
    if (Test-Path Function:Test-CachedCommand -ErrorAction SilentlyContinue) {
        Set-Item -Path Function:Find-FileFuzzy -Value { param([string]$pattern = '') if (Test-CachedCommand fzf) { Get-ChildItem -Recurse -File | Where-Object { $_.Name -match $pattern } | fzf } else { Write-Warning 'fzf not found' } } -Force | Out-Null
    }
    else {
        Set-Item -Path Function:Find-FileFuzzy -Value { param([string]$pattern = '') if (Get-Command fzf -ErrorAction SilentlyContinue) { Get-ChildItem -Recurse -File | Where-Object { $_.Name -match $pattern } | fzf } else { Write-Warning 'fzf not found' } } -Force | Out-Null
    }
    Set-Alias -Name ff -Value Find-FileFuzzy -ErrorAction SilentlyContinue
}

# fcmd: fuzzy-find a command
if (-not (Test-Path Function:Find-CommandFuzzy -ErrorAction SilentlyContinue)) {
    if (Test-Path Function:Test-CachedCommand -ErrorAction SilentlyContinue) {
        Set-Item -Path Function:Find-CommandFuzzy -Value { if (Test-CachedCommand fzf) { Get-Command | Out-String | fzf } else { Write-Warning 'fzf not found' } } -Force | Out-Null
    }
    else {
        Set-Item -Path Function:Find-CommandFuzzy -Value { if (Get-Command fzf -ErrorAction SilentlyContinue) { Get-Command | Out-String | fzf } else { Write-Warning 'fzf not found' } } -Force | Out-Null
    }
    Set-Alias -Name fcmd -Value Find-CommandFuzzy -ErrorAction SilentlyContinue
}
