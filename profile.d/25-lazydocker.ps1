# ===============================================
# 25-lazydocker.ps1
# lazydocker wrapper helpers
# ===============================================

if (-not (Test-Path Function:ld -ErrorAction SilentlyContinue)) {
    # Use Test-HasCommand which handles caching and fallback internally
    Set-Item -Path Function:ld -Value { if (Test-HasCommand lazydocker) { lazydocker @Args } else { Write-Warning 'lazydocker not found' } } -Force | Out-Null
}
