# ===============================================
# 69-pnpm.ps1
# Fast package manager with pnpm
# ===============================================

# PNPM aliases
# Requires: pnpm (https://pnpm.io/)

if (Test-HasCommand pnpm) {
    # PNPM as npm replacement
    Set-Alias -Name npm -Value pnpm -Option AllScope -Force
    Set-Alias -Name yarn -Value pnpm -Option AllScope -Force

    # Common pnpm commands
    <#
    .SYNOPSIS
        Installs packages using pnpm.
    .DESCRIPTION
        Adds packages as dependencies to the project using pnpm.
    #>
    function Invoke-PnpmInstall {
        param([string[]]$Packages)
        pnpm add @Packages
    }
    Set-Alias -Name pnadd -Value Invoke-PnpmInstall -Option AllScope -Force

    <#
    .SYNOPSIS
        Installs development packages using pnpm.
    .DESCRIPTION
        Adds packages as dev dependencies to the project using pnpm.
    #>
    function Invoke-PnpmDevInstall {
        param([string[]]$Packages)
        pnpm add -D @Packages
    }
    Set-Alias -Name pndev -Value Invoke-PnpmDevInstall -Option AllScope -Force

    <#
    .SYNOPSIS
        Runs npm scripts using pnpm.
    .DESCRIPTION
        Executes package.json scripts using pnpm instead of npm.
    #>
    function Invoke-PnpmRun {
        param([string]$Script, [string[]]$Args)
        pnpm run $Script @Args
    }
    Set-Alias -Name pnrun -Value Invoke-PnpmRun -Option AllScope -Force
}
else {
    Write-MissingToolWarning -Tool 'pnpm' -InstallHint 'Install with: scoop install pnpm'
}
