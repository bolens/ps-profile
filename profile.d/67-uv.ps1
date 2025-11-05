# ===============================================
# 67-uv.ps1
# Python package manager with uv
# ===============================================

# UV aliases and functions
# Requires: uv (https://github.com/astral-sh/uv)

if (Test-HasCommand uv) {
    # UV pip replacement
    <#
    .SYNOPSIS
        Python package manager using uv instead of pip.
    .DESCRIPTION
        Replacement for pip that uses uv for faster Python package management.
    #>
    function Invoke-Pip { uv pip @args }
    Set-Alias -Name pip -Value Invoke-Pip -ErrorAction SilentlyContinue

    # UV run
    <#
    .SYNOPSIS
        Runs Python commands in temporary virtual environments using uv.
    .DESCRIPTION
        Executes Python commands with their dependencies automatically managed in isolated environments.
    #>
    function Invoke-UVRun {
        param([string]$Command, [string[]]$Args)
        uv run $Command @Args
    }
    Set-Alias -Name uvrun -Value Invoke-UVRun -Option AllScope -Force

    # UV tool install
    <#
    .SYNOPSIS
        Installs Python tools globally using uv.
    .DESCRIPTION
        Installs Python applications as standalone executables using uv's tool management.
    #>
    function Install-UVTool {
        param([string]$Package)
        uv tool install $Package
    }
    Set-Alias -Name uvtool -Value Install-UVTool -Option AllScope -Force

    # UV venv
    <#
    .SYNOPSIS
        Creates Python virtual environments using uv.
    .DESCRIPTION
        Creates virtual environments much faster than traditional venv or virtualenv.
    #>
    function New-UVVenv {
        param([string]$Path = ".venv")
        uv venv $Path
    }
    Set-Alias -Name uvvenv -Value New-UVVenv -Option AllScope -Force
}
else {
    Write-Warning "uv not found. Install with: scoop install uv"
}
