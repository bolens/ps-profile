# ===============================================
# 30-open.ps1
# Cross-platform 'open' helper
# ===============================================

if (-not (Test-Path Function:open -ErrorAction SilentlyContinue)) {
    function open {
        param($p)
        if ($IsWindows) { Start-Process -FilePath $p } else {
            if (Test-Path Function:'xdg-open' -ErrorAction SilentlyContinue -or $null -NE (Get-Command xdg-open -ErrorAction SilentlyContinue)) { xdg-open $p }
            elseif (Test-Path Function:'open' -ErrorAction SilentlyContinue -or $null -NE (Get-Command open -ErrorAction SilentlyContinue)) { open $p }
            else { Write-Warning "No opener found for $p" }
        }
    }
}








