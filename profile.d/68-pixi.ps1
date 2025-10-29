# ===============================================
# 68-pixi.ps1
# Package management with pixi
# ===============================================

# Pixi aliases
# Requires: pixi (https://github.com/prefix-dev/pixi)

if (Get-Command pixi -ErrorAction SilentlyContinue) {
    # Common pixi commands
    function Invoke-PixiInstall {
        param([string]$Package)
        pixi add $Package
    }
    Set-Alias -Name pxadd -Value Invoke-PixiInstall -Option AllScope -Force

    function Invoke-PixiRun {
        param([string]$Command, [string[]]$Args)
        pixi run $Command @Args
    }
    Set-Alias -Name pxrun -Value Invoke-PixiRun -Option AllScope -Force

    function Invoke-PixiShell {
        pixi shell
    }
    Set-Alias -Name pxshell -Value Invoke-PixiShell -Option AllScope -Force
}
else {
    Write-Warning "pixi not found. Install with: scoop install pixi"
}







