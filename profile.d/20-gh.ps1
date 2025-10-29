# ===============================================
# 20-gh.ps1
# GitHub CLI helpers (guarded)
# ===============================================

# GitHub open - open repository in web browser
if (-not (Test-Path Function:gh-open -ErrorAction SilentlyContinue)) {
    Set-Item -Path Function:gh-open -Value { param($p) if (-not $p) { gh repo view --web } else { gh repo view $p --web } } -Force | Out-Null
}

# GitHub PR management - manage pull requests
if (-not (Test-Path Function:gh-pr -ErrorAction SilentlyContinue)) {
    Set-Item -Path Function:gh-pr -Value { param($Params) gh pr $Params } -Force | Out-Null
}








