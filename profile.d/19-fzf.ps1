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
    # Use Test-HasCommand which handles caching and fallback internally
    Set-Item -Path Function:Find-FileFuzzy -Value { param([string]$pattern = '') if (Test-HasCommand fzf) { Get-ChildItem -Recurse -File | Where-Object { $_.Name -match $pattern } | fzf } else { Write-Warning 'fzf not found' } } -Force | Out-Null
    Set-Alias -Name ff -Value Find-FileFuzzy -ErrorAction SilentlyContinue
}

# fcmd: fuzzy-find a command
if (-not (Test-Path Function:Find-CommandFuzzy -ErrorAction SilentlyContinue)) {
    # Use Test-HasCommand which handles caching and fallback internally
    Set-Item -Path Function:Find-CommandFuzzy -Value { if (Test-HasCommand fzf) { Get-Command | Out-String | fzf } else { Write-Warning 'fzf not found' } } -Force | Out-Null
    Set-Alias -Name fcmd -Value Find-CommandFuzzy -ErrorAction SilentlyContinue
}
