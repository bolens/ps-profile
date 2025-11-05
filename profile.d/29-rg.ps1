# ===============================================
# 29-rg.ps1
# ripgrep wrapper helpers (guarded)
# ===============================================

if (-not (Test-Path Function:rgf -ErrorAction SilentlyContinue)) {
    # Use Test-HasCommand which handles caching and fallback internally
    Set-Item -Path Function:rgf -Value { param($p) if (Test-HasCommand rg) { rg --line-number --hidden -s $p } else { Write-Warning 'rg not found' } } -Force | Out-Null
}
