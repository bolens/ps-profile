# ===============================================
# 66-dust.ps1
# Modern disk usage analyzer with dust
# ===============================================

# Dust aliases
# Requires: dust (https://github.com/bootandy/dust)

if (Get-Command dust -ErrorAction SilentlyContinue) {
    # Main dust command
    Set-Alias -Name du -Value dust -Option AllScope -Force
    Set-Alias -Name diskusage -Value dust -Option AllScope -Force
}
else {
    Write-Warning "dust not found. Install with: scoop install dust"
}







