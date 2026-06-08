# ===============================================
# uv.ps1
# Python package manager with uv
# ===============================================

# UV aliases and functions
# Requires: uv (https://github.com/astral-sh/uv)
# Tier: standard
# Dependencies: bootstrap, env

if (Test-CachedCommand uv) {
    <#
.SYNOPSIS
        Python package manager using uv instead of pip.

    .DESCRIPTION
        Replacement for pip that uses uv for faster Python package management.

.PARAMETER Arguments
    Arguments forwarded to uv pip.

.EXAMPLE
    Invoke-Pip install requests

#>
    function Invoke-Pip {
        [CmdletBinding()]
        param(
            [Parameter(ValueFromRemainingArguments = $true)]
            [object[]]$Arguments
        )

        uv pip @Arguments
    }

    <#
.SYNOPSIS
        Runs Python commands in temporary virtual environments using uv.

    .DESCRIPTION
        Executes Python commands with their dependencies automatically managed in isolated environments.

.PARAMETER Command
    Python module or script to run with uv run.

.PARAMETER Args
    Additional arguments passed after the command.

.EXAMPLE
    Invoke-UVRun -Command python -Args @('--version')

#>
    function Invoke-UVRun {
        param(
            [string]$Command,
            [string[]]$Args
        )
        uv run $Command @Args
    }

    <#
.SYNOPSIS
        Installs Python tools globally using uv.

    .DESCRIPTION
        Installs Python applications as standalone executables using uv's tool management.

.PARAMETER Package
    Python package name to install as a global uv tool.

.EXAMPLE
    Install-UVTool 'package-name'

#>
    function Install-UVTool {
        param([string]$Package)
        uv tool install $Package
    }

    <#
.SYNOPSIS
        Creates Python virtual environments using uv.

    .DESCRIPTION
        Creates virtual environments much faster than traditional venv or virtualenv.

.PARAMETER Path
    Directory path where the virtual environment should be created.

.EXAMPLE
    New-UVVenv -Path .venv

#>
    function New-UVVenv {
        param([string]$Path = '.venv')
        uv venv $Path
    }

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

        Write-Verbose 'Checking for outdated packages...'
        uv pip list --outdated

        Write-Verbose 'Upgrading all packages...'
        $packages = uv pip freeze | ForEach-Object { $_.Split('==')[0] }
        if ($packages) {
            foreach ($package in $packages) {
                Write-Verbose "Upgrading $package..."
                uv pip install --upgrade $package
            }
        }
        else {
            Write-Output 'No packages found to upgrade.'
        }
    }

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

        Write-Verbose 'Upgrading all uv tools...'
        uv tool upgrade --all
    }

    <#
.SYNOPSIS
        Runs tools installed with UV.

    .DESCRIPTION
        Executes tools that were installed using uv tool install.

.PARAMETER Arguments
    Arguments forwarded to uv tool run.

.EXAMPLE
    Invoke-UVTool ruff --version

#>
    function Invoke-UVTool {
        [CmdletBinding()]
        param(
            [Parameter(ValueFromRemainingArguments = $true)]
            [object[]]$Arguments
        )

        uv tool run @Arguments
    }

    <#
.SYNOPSIS
        Adds dependencies to UV project.

    .DESCRIPTION
        Adds packages as dependencies to the current UV project.

.PARAMETER Arguments
    Package names and flags forwarded to uv add.

.EXAMPLE
    Add-UVDependency requests

#>
    function Add-UVDependency {
        [CmdletBinding()]
        param(
            [Parameter(ValueFromRemainingArguments = $true)]
            [object[]]$Arguments
        )

        uv add @Arguments
    }

    <#
.SYNOPSIS
        Syncs UV project dependencies.

    .DESCRIPTION
        Installs and synchronizes all project dependencies.

.PARAMETER Arguments
    Optional flags forwarded to uv sync.

.EXAMPLE
    Sync-UVDependencies
#>
    function Sync-UVDependencies {
        [CmdletBinding()]
        param(
            [Parameter(ValueFromRemainingArguments = $true)]
            [object[]]$Arguments
        )

        uv sync @Arguments
    }

    if (Get-Command Set-AgentModeFunction -ErrorAction SilentlyContinue) {
        Set-AgentModeFunction -Name 'Invoke-Pip' -Body ${function:Invoke-Pip}
        Set-AgentModeFunction -Name 'Invoke-UVRun' -Body ${function:Invoke-UVRun}
        Set-AgentModeFunction -Name 'Install-UVTool' -Body ${function:Install-UVTool}
        Set-AgentModeFunction -Name 'New-UVVenv' -Body ${function:New-UVVenv}
        Set-AgentModeFunction -Name 'Update-UVOutdatedPackages' -Body ${function:Update-UVOutdatedPackages}
        Set-AgentModeFunction -Name 'Update-UVTools' -Body ${function:Update-UVTools}
        Set-AgentModeFunction -Name 'Invoke-UVTool' -Body ${function:Invoke-UVTool}
        Set-AgentModeFunction -Name 'Add-UVDependency' -Body ${function:Add-UVDependency}
        Set-AgentModeFunction -Name 'Sync-UVDependencies' -Body ${function:Sync-UVDependencies}

        Set-AgentModeAlias -Name 'pip' -Target 'Invoke-Pip'
        Set-AgentModeAlias -Name 'uvrun' -Target 'Invoke-UVRun'
        Set-AgentModeAlias -Name 'uvtool' -Target 'Install-UVTool'
        Set-AgentModeAlias -Name 'uvvenv' -Target 'New-UVVenv'
        Set-AgentModeAlias -Name 'uvupgrade' -Target 'Update-UVOutdatedPackages'
        Set-AgentModeAlias -Name 'uvtoolupgrade' -Target 'Update-UVTools'
        Set-AgentModeAlias -Name 'uvx' -Target 'Invoke-UVTool'
        Set-AgentModeAlias -Name 'uva' -Target 'Add-UVDependency'
        Set-AgentModeAlias -Name 'uvs' -Target 'Sync-UVDependencies'
    }
}
else {
    Invoke-MissingToolWarning -ToolName 'uv' -ToolType 'python-package'
}
