# ===============================================
# 65-procs.ps1
# Modern process viewer with procs
# ===============================================

# Procs aliases
# Requires: procs (https://github.com/dalance/procs)

if (Get-Command procs -ErrorAction SilentlyContinue) {
    # Main procs command
    Set-Alias -Name ps -Value procs -Option AllScope -Force
    Set-Alias -Name psgrep -Value procs -Option AllScope -Force
}
else {
    Write-Warning "procs not found. Install with: scoop install procs"
}


















