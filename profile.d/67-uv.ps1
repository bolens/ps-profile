# ===============================================
# 67-uv.ps1
# Python package manager with uv
# ===============================================

# UV aliases and functions
# Requires: uv (https://github.com/astral-sh/uv)

if (Get-Command uv -ErrorAction SilentlyContinue) {
    # UV pip replacement
    function pip { uv pip @args }

    # UV run
    function Invoke-UVRun {
        param([string]$Command, [string[]]$Args)
        uv run $Command @Args
    }
    Set-Alias -Name uvrun -Value Invoke-UVRun -Option AllScope -Force

    # UV tool install
    function Install-UVTool {
        param([string]$Package)
        uv tool install $Package
    }
    Set-Alias -Name uvtool -Value Install-UVTool -Option AllScope -Force

    # UV venv
    function New-UVVenv {
        param([string]$Path = ".venv")
        uv venv $Path
    }
    Set-Alias -Name uvvenv -Value New-UVVenv -Option AllScope -Force
}
else {
    Write-Warning "uv not found. Install with: scoop install uv"
}

