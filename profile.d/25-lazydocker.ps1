# ===============================================
# 25-lazydocker.ps1
# lazydocker wrapper helpers
# ===============================================

if (-not (Test-Path Function:ld -ErrorAction SilentlyContinue)) {
    Set-Item -Path Function:ld -Value { if (Test-Path Function:Test-CachedCommand -ErrorAction SilentlyContinue) { if (Test-CachedCommand lazydocker) { lazydocker @Args } else { Write-Warning 'lazydocker not found' } } else { if (Get-Command lazydocker -ErrorAction SilentlyContinue) { lazydocker @Args } else { Write-Warning 'lazydocker not found' } } } -Force | Out-Null
}










