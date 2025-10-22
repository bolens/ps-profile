# ===============================================
# 26-rg.ps1
# ripgrep wrapper helpers (guarded)
# ===============================================

if (-not (Test-Path Function:rgf -ErrorAction SilentlyContinue)) {
  Set-Item -Path Function:rgf -Value { param($p) if (Test-Path Function:Test-CachedCommand -ErrorAction SilentlyContinue) { if (Test-CachedCommand rg) { rg --line-number --hidden -s $p } else { Write-Warning 'rg not found' } } else { if ($null -ne (Get-Command rg -ErrorAction SilentlyContinue)) { rg --line-number --hidden -s $p } else { Write-Warning 'rg not found' } } } -Force | Out-Null
}
