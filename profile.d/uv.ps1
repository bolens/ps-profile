# ===============================================
# uv.ps1
# Python package manager with uv
# ===============================================

# UV aliases and functions
# Requires: uv (https://github.com/astral-sh/uv)
# Tier: standard
# Dependencies: bootstrap, env

if (Test-CachedCommand uv) {
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

    # Upgrade all outdated packages
    <#
    .SYNOPSIS
        Upgrades all outdated Python packages using uv.
    .DESCRIPTION
        Lists all outdated packages and upgrades them to their latest versions.
        This is a uv-compatible replacement for pip-based upgrade commands.
    .EXAMPLE
        Update-UVOutdatedPackages
        Upgrades all outdated packages in the current environment.
    #>
    function Update-UVOutdatedPackages {
        [CmdletBinding()]
        param()

        Write-Verbose "Checking for outdated packages..."
        uv pip list --outdated

        Write-Verbose "Upgrading all packages..."
        $packages = uv pip freeze | ForEach-Object { $_.Split('==')[0] }
        if ($packages) {
            foreach ($package in $packages) {
                Write-Verbose "Upgrading $package..."
                uv pip install --upgrade $package
            }
        }
        else {
            Write-Output "No packages found to upgrade."
        }
    }
    Set-Alias -Name uvupgrade -Value Update-UVOutdatedPackages -Option AllScope -Force

    # Upgrade all uv tools
    <#
    .SYNOPSIS
        Upgrades all globally installed uv tools to their latest versions.
    .DESCRIPTION
        Upgrades all Python tools that were installed globally using uv tool install.
        This is equivalent to running 'uv tool upgrade --all'.
    .EXAMPLE
        Update-UVTools
        Upgrades all globally installed uv tools.
    #>
    function Update-UVTools {
        [CmdletBinding()]
        param()

        Write-Verbose "Upgrading all uv tools..."
        uv tool upgrade --all
    }
    Set-Alias -Name uvtoolupgrade -Value Update-UVTools -Option AllScope -Force

    # UV pip install/uninstall - use via Invoke-Pip alias
    # Note: The Invoke-Pip function already provides uv pip install/uninstall functionality
    # Users can use: pip install package or pip uninstall package

    # UV tool run
    <#
    .SYNOPSIS
        Runs tools installed with UV.
    .DESCRIPTION
        Executes tools that were installed using uv tool install.
    #>
    function Invoke-UVTool { uv tool run @args }
    Set-Alias -Name uvx -Value Invoke-UVTool -ErrorAction SilentlyContinue

    # UV add
    <#
    .SYNOPSIS
        Adds dependencies to UV project.
    .DESCRIPTION
        Adds packages as dependencies to the current UV project.
    #>
    function Add-UVDependency { uv add @args }
    Set-Alias -Name uva -Value Add-UVDependency -ErrorAction SilentlyContinue

    # UV sync
    <#
    .SYNOPSIS
        Syncs UV project dependencies.
    .DESCRIPTION
        Installs and synchronizes all project dependencies.
    #>
    function Sync-UVDependencies { uv sync @args }
    Set-Alias -Name uvs -Value Sync-UVDependencies -ErrorAction SilentlyContinue
}
else {
    $installHint = if (Get-Command Get-PreferenceAwareInstallHint -ErrorAction SilentlyContinue) {
        Get-PreferenceAwareInstallHint -ToolName 'uv' -ToolType 'python-package'
    }
    else {
        'Install with: scoop install uv'
    }
    Write-MissingToolWarning -Tool 'uv' -InstallHint $installHint
}
