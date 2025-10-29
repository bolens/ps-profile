# ===============================================
# 69-pnpm.ps1
# Fast package manager with pnpm
# ===============================================

# PNPM aliases
# Requires: pnpm (https://pnpm.io/)

if (Get-Command pnpm -ErrorAction SilentlyContinue) {
    # PNPM as npm replacement
    Set-Alias -Name npm -Value pnpm -Option AllScope -Force
    Set-Alias -Name yarn -Value pnpm -Option AllScope -Force

    # Common pnpm commands
    function Invoke-PnpmInstall {
        param([string[]]$Packages)
        pnpm add @Packages
    }
    Set-Alias -Name pnadd -Value Invoke-PnpmInstall -Option AllScope -Force

    function Invoke-PnpmDevInstall {
        param([string[]]$Packages)
        pnpm add -D @Packages
    }
    Set-Alias -Name pndev -Value Invoke-PnpmDevInstall -Option AllScope -Force

    function Invoke-PnpmRun {
        param([string]$Script, [string[]]$Args)
        pnpm run $Script @Args
    }
    Set-Alias -Name pnrun -Value Invoke-PnpmRun -Option AllScope -Force
}
else {
    Write-Warning "pnpm not found. Install with: scoop install pnpm"
}





