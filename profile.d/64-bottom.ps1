# ===============================================
# 64-bottom.ps1
# System monitor with bottom
# ===============================================

# Bottom aliases
# Requires: bottom (https://github.com/ClementTsang/bottom)

if (Get-Command btm -ErrorAction SilentlyContinue) {
    # Main bottom command
    Set-Alias -Name top -Value btm -Option AllScope -Force
    Set-Alias -Name htop -Value btm -Option AllScope -Force
    Set-Alias -Name monitor -Value btm -Option AllScope -Force
}
elseif (Get-Command bottom -ErrorAction SilentlyContinue) {
    Set-Alias -Name top -Value bottom -Option AllScope -Force
    Set-Alias -Name htop -Value bottom -Option AllScope -Force
    Set-Alias -Name monitor -Value bottom -Option AllScope -Force
}
else {
    Write-Warning "bottom (btm) not found. Install with: scoop install bottom"
}
















