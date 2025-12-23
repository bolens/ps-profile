# ===============================================
# lang-python.ps1
# Python development tools (enhanced)
# ===============================================
# Tier: standard
# Dependencies: bootstrap, env

<#
.SYNOPSIS
    Python development tools fragment for enhanced Python development workflows.

.DESCRIPTION
    Provides wrapper functions for Python development tools that enhance existing
    Python package manager support (uv.ps1, pixi.ps1, package-managers.ps1):
    - pipx: Python application installer and runner
    - python: Python interpreter wrapper
    - Project creation helpers
    - Virtual environment management
    - Script execution helpers

.NOTES
    All functions gracefully degrade when tools are not installed.
    This module enhances existing Python tool support (uv, pixi, pip).
#>

try {
    # Idempotency check: skip if already loaded
    if (Get-Command Test-FragmentLoaded -ErrorAction SilentlyContinue) {
        if (Test-FragmentLoaded -FragmentName 'lang-python') { return }
    }

    # Import Command module for Get-ToolInstallHint (if not already available)
    if (-not (Get-Command Get-ToolInstallHint -ErrorAction SilentlyContinue)) {
        $repoRoot = $null
        if (Get-Command Get-RepoRoot -ErrorAction SilentlyContinue) {
            try {
                $repoRoot = Get-RepoRoot -ScriptPath $PSScriptRoot -ErrorAction Stop
            }
            catch {
                # Get-RepoRoot expects scripts/ subdirectory, but we're in profile.d/
                # Fall back to manual path resolution
                $repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
            }
        }
        else {
            $repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
        }

        if ($repoRoot) {
            $commandModulePath = Join-Path $repoRoot 'scripts' 'lib' 'utilities' 'Command.psm1'
            if (Test-Path -LiteralPath $commandModulePath) {
                Import-Module $commandModulePath -DisableNameChecking -ErrorAction SilentlyContinue
            }
        }
    }

    # ===============================================
    # pipx - Python application installer
    # ===============================================

    <#
    .SYNOPSIS
        Installs Python applications using pipx.

    .DESCRIPTION
        Wrapper function for pipx, which installs Python applications in isolated
        environments. pipx is similar to npm's global install or cargo install.

    .PARAMETER Packages
        Package names to install.
        Can be used multiple times or as an array.

    .PARAMETER Arguments
        Additional arguments to pass to pipx install.
        Can be used multiple times or as an array.

    .EXAMPLE
        Install-PythonApp black
        Installs black as a standalone application.

    .EXAMPLE
        Install-PythonApp pytest --include-deps
        Installs pytest with additional dependencies.

    .OUTPUTS
        System.String. Output from pipx install execution.
    #>
    function Install-PythonApp {
        [CmdletBinding()]
        [OutputType([string])]
        param(
            [Parameter(Mandatory, ValueFromRemainingArguments = $true)]
            [string[]]$Packages,

            [Parameter()]
            [string[]]$Arguments
        )

        if (-not (Test-CachedCommand 'pipx')) {
            $repoRoot = $null
            if (Get-Command Get-RepoRoot -ErrorAction SilentlyContinue) {
                try {
                    $repoRoot = Get-RepoRoot -ScriptPath $PSScriptRoot -ErrorAction Stop
                }
                catch {
                    $repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
                }
            }
            else {
                $repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
            }
            $installHint = if (Get-Command Get-ToolInstallHint -ErrorAction SilentlyContinue) {
                Get-ToolInstallHint -ToolName 'pipx' -RepoRoot $repoRoot
            }
            else {
                "Install with: pip install pipx (or python -m pip install pipx)"
            }
            if (Get-Command Write-MissingToolWarning -ErrorAction SilentlyContinue) {
                Write-MissingToolWarning -Tool 'pipx' -InstallHint $installHint
            }
            else {
                Write-Warning "pipx not found. $installHint"
            }
            return $null
        }

        try {
            $cmdArgs = @('install')
            if ($Arguments) {
                $cmdArgs += $Arguments
            }
            $cmdArgs += $Packages
            $result = & pipx @cmdArgs 2>&1
            return $result
        }
        catch {
            Write-Error "Failed to run pipx install: $($_.Exception.Message)"
            return $null
        }
    }

    if (-not (Test-Path Function:\Install-PythonApp -ErrorAction SilentlyContinue)) {
        Set-AgentModeFunction -Name 'Install-PythonApp' -Body ${function:Install-PythonApp}
    }
    if (-not (Get-Alias pipx-install -ErrorAction SilentlyContinue)) {
        if (Get-Command Set-AgentModeAlias -ErrorAction SilentlyContinue) {
            Set-AgentModeAlias -Name 'pipx-install' -Target 'Install-PythonApp'
        }
        else {
            Set-Alias -Name 'pipx-install' -Value 'Install-PythonApp' -ErrorAction SilentlyContinue
        }
    }

    <#
    .SYNOPSIS
        Runs pipx-installed applications.

    .DESCRIPTION
        Wrapper function for pipx run, which runs Python applications in isolated
        environments without installing them globally.

    .PARAMETER Package
        Package name to run.

    .PARAMETER Arguments
        Arguments to pass to the application.
        Can be used multiple times or as an array.

    .EXAMPLE
        Invoke-Pipx black --check .
        Runs black in an isolated environment to check code formatting.

    .EXAMPLE
        Invoke-Pipx pytest tests/
        Runs pytest in an isolated environment.

    .OUTPUTS
        System.String. Output from pipx run execution.
    #>
    function Invoke-Pipx {
        [CmdletBinding()]
        [OutputType([string])]
        param(
            [Parameter(Mandatory)]
            [string]$Package,

            [Parameter(ValueFromRemainingArguments = $true)]
            [string[]]$Arguments
        )

        if (-not (Test-CachedCommand 'pipx')) {
            $repoRoot = $null
            if (Get-Command Get-RepoRoot -ErrorAction SilentlyContinue) {
                try {
                    $repoRoot = Get-RepoRoot -ScriptPath $PSScriptRoot -ErrorAction Stop
                }
                catch {
                    $repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
                }
            }
            else {
                $repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
            }
            $installHint = if (Get-Command Get-ToolInstallHint -ErrorAction SilentlyContinue) {
                Get-ToolInstallHint -ToolName 'pipx' -RepoRoot $repoRoot
            }
            else {
                "Install with: pip install pipx (or python -m pip install pipx)"
            }
            if (Get-Command Write-MissingToolWarning -ErrorAction SilentlyContinue) {
                Write-MissingToolWarning -Tool 'pipx' -InstallHint $installHint
            }
            else {
                Write-Warning "pipx not found. $installHint"
            }
            return $null
        }

        try {
            $cmdArgs = @('run', $Package)
            if ($Arguments) {
                $cmdArgs += $Arguments
            }
            $result = & pipx @cmdArgs 2>&1
            return $result
        }
        catch {
            Write-Error "Failed to run pipx: $($_.Exception.Message)"
            return $null
        }
    }

    if (-not (Test-Path Function:\Invoke-Pipx -ErrorAction SilentlyContinue)) {
        Set-AgentModeFunction -Name 'Invoke-Pipx' -Body ${function:Invoke-Pipx}
    }
    if (-not (Get-Alias pipx -ErrorAction SilentlyContinue)) {
        if (Get-Command Set-AgentModeAlias -ErrorAction SilentlyContinue) {
            Set-AgentModeAlias -Name 'pipx' -Target 'Invoke-Pipx'
        }
        else {
            Set-Alias -Name 'pipx' -Value 'Invoke-Pipx' -ErrorAction SilentlyContinue
        }
    }

    # ===============================================
    # Python - Python interpreter wrapper
    # ===============================================

    <#
    .SYNOPSIS
        Runs Python scripts and commands.

    .DESCRIPTION
        Wrapper function for the Python interpreter that provides consistent
        execution across different Python installations.

    .PARAMETER Script
        Python script file to execute (optional).

    .PARAMETER Arguments
        Arguments to pass to Python or the script.
        Can be used multiple times or as an array.

    .EXAMPLE
        Invoke-PythonScript script.py
        Runs a Python script.

    .EXAMPLE
        Invoke-PythonScript -Arguments @('-c', 'print("Hello")')
        Runs a Python one-liner.

    .OUTPUTS
        System.String. Output from Python execution.
    #>
    function Invoke-PythonScript {
        [CmdletBinding()]
        [OutputType([string])]
        param(
            [Parameter()]
            [string]$Script,

            [Parameter(ValueFromRemainingArguments = $true)]
            [string[]]$Arguments
        )

        # Try python3 first, then python
        $pythonCmd = $null
        if (Test-CachedCommand 'python3') {
            $pythonCmd = 'python3'
        }
        elseif (Test-CachedCommand 'python') {
            $pythonCmd = 'python'
        }

        if (-not $pythonCmd) {
            $repoRoot = $null
            if (Get-Command Get-RepoRoot -ErrorAction SilentlyContinue) {
                try {
                    $repoRoot = Get-RepoRoot -ScriptPath $PSScriptRoot -ErrorAction Stop
                }
                catch {
                    $repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
                }
            }
            else {
                $repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
            }
            $installHint = if (Get-Command Get-ToolInstallHint -ErrorAction SilentlyContinue) {
                Get-ToolInstallHint -ToolName 'python' -RepoRoot $repoRoot
            }
            else {
                "Install Python from python.org or use: scoop install python"
            }
            if (Get-Command Write-MissingToolWarning -ErrorAction SilentlyContinue) {
                Write-MissingToolWarning -Tool 'python' -InstallHint $installHint
            }
            else {
                Write-Warning "python not found. $installHint"
            }
            return $null
        }

        try {
            $cmdArgs = @()
            if ($Script) {
                $cmdArgs += $Script
            }
            if ($Arguments) {
                $cmdArgs += $Arguments
            }
            $result = & $pythonCmd @cmdArgs 2>&1
            return $result
        }
        catch {
            Write-Error "Failed to run python: $($_.Exception.Message)"
            return $null
        }
    }

    if (-not (Test-Path Function:\Invoke-PythonScript -ErrorAction SilentlyContinue)) {
        Set-AgentModeFunction -Name 'Invoke-PythonScript' -Body ${function:Invoke-PythonScript}
    }

    # ===============================================
    # Create Python Virtual Environment
    # ===============================================

    <#
    .SYNOPSIS
        Creates a Python virtual environment.

    .DESCRIPTION
        Creates a Python virtual environment using the best available tool:
        - uv (if available) - fastest option
        - python -m venv (if available) - standard library option
        Falls back gracefully if neither is available.

    .PARAMETER Path
        Path where the virtual environment should be created.
        Defaults to '.venv' in the current directory.

    .PARAMETER PythonVersion
        Python version to use (for uv only).

    .EXAMPLE
        New-PythonVirtualEnv
        Creates a virtual environment in .venv.

    .EXAMPLE
        New-PythonVirtualEnv -Path 'venv'
        Creates a virtual environment in 'venv'.

    .OUTPUTS
        System.String. Output from virtual environment creation.
    #>
    function New-PythonVirtualEnv {
        [CmdletBinding()]
        [OutputType([string])]
        param(
            [Parameter()]
            [string]$Path = '.venv',

            [Parameter()]
            [string]$PythonVersion
        )

        # Prefer uv if available (fastest)
        if (Test-CachedCommand 'uv') {
            try {
                $cmdArgs = @('venv', $Path)
                if ($PythonVersion) {
                    $cmdArgs += '--python', $PythonVersion
                }
                $result = & uv @cmdArgs 2>&1
                return $result
            }
            catch {
                Write-Warning "Failed to create venv with uv: $($_.Exception.Message). Trying python -m venv..."
            }
        }

        # Fallback to python -m venv
        $pythonCmd = $null
        if (Test-CachedCommand 'python3') {
            $pythonCmd = 'python3'
        }
        elseif (Test-CachedCommand 'python') {
            $pythonCmd = 'python'
        }

        if ($pythonCmd) {
            try {
                $result = & $pythonCmd -m venv $Path 2>&1
                return $result
            }
            catch {
                Write-Error "Failed to create venv with python: $($_.Exception.Message)"
                return $null
            }
        }

        # No Python available
        $repoRoot = $null
        if (Get-Command Get-RepoRoot -ErrorAction SilentlyContinue) {
            try {
                $repoRoot = Get-RepoRoot -ScriptPath $PSScriptRoot -ErrorAction Stop
            }
            catch {
                $repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
            }
        }
        else {
            $repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
        }
        $installHint = if (Get-Command Get-ToolInstallHint -ErrorAction SilentlyContinue) {
            Get-ToolInstallHint -ToolName 'python' -RepoRoot $repoRoot
        }
        else {
            "Install Python from python.org or use: scoop install python (or uv)"
        }
        if (Get-Command Write-MissingToolWarning -ErrorAction SilentlyContinue) {
            Write-MissingToolWarning -Tool 'python' -InstallHint $installHint
        }
        else {
            Write-Warning "Neither uv nor python found. $installHint"
        }
        return $null
    }

    if (-not (Test-Path Function:\New-PythonVirtualEnv -ErrorAction SilentlyContinue)) {
        Set-AgentModeFunction -Name 'New-PythonVirtualEnv' -Body ${function:New-PythonVirtualEnv}
    }
    if (-not (Get-Alias pyvenv -ErrorAction SilentlyContinue)) {
        if (Get-Command Set-AgentModeAlias -ErrorAction SilentlyContinue) {
            Set-AgentModeAlias -Name 'pyvenv' -Target 'New-PythonVirtualEnv'
        }
        else {
            Set-Alias -Name 'pyvenv' -Value 'New-PythonVirtualEnv' -ErrorAction SilentlyContinue
        }
    }

    # ===============================================
    # Create Python Project
    # ===============================================

    <#
    .SYNOPSIS
        Creates a new Python project structure.

    .DESCRIPTION
        Creates a new Python project with a basic structure including:
        - Project directory
        - README.md
        - .gitignore (Python-specific)
        - pyproject.toml or requirements.txt (depending on available tools)

    .PARAMETER Name
        Project name (also used as directory name).

    .PARAMETER Path
        Parent directory where the project should be created.
        Defaults to current directory.

    .PARAMETER UseUV
        Use uv for project initialization (if available).

    .EXAMPLE
        New-PythonProject myproject
        Creates a new Python project named 'myproject'.

    .EXAMPLE
        New-PythonProject myproject -Path 'C:\Projects' -UseUV
        Creates a project using uv in the specified path.

    .OUTPUTS
        System.String. Path to the created project directory.
    #>
    function New-PythonProject {
        [CmdletBinding()]
        [OutputType([string])]
        param(
            [Parameter(Mandatory)]
            [string]$Name,

            [Parameter()]
            [string]$Path = '.',

            [Parameter()]
            [switch]$UseUV
        )

        try {
            $projectPath = Join-Path $Path $Name

            # Create project directory
            if (-not (Test-Path -LiteralPath $projectPath)) {
                New-Item -ItemType Directory -Path $projectPath -Force | Out-Null
            }

            # Create README.md
            $readmePath = Join-Path $projectPath 'README.md'
            if (-not (Test-Path -LiteralPath $readmePath)) {
                $readmeContent = @"
# $Name

Python project created with lang-python.ps1

## Setup

\`\`\`bash
# Create virtual environment
python -m venv .venv

# Activate virtual environment
# Windows:
.venv\Scripts\Activate.ps1
# Unix:
source .venv/bin/activate

# Install dependencies
pip install -r requirements.txt
\`\`\`

## Usage

\`\`\`bash
python main.py
\`\`\`
"@
                Set-Content -Path $readmePath -Value $readmeContent
            }

            # Create .gitignore
            $gitignorePath = Join-Path $projectPath '.gitignore'
            if (-not (Test-Path -LiteralPath $gitignorePath)) {
                $gitignoreContent = @"
# Python
__pycache__/
*.py[cod]
*$py.class
*.so
.Python
build/
develop-eggs/
dist/
downloads/
eggs/
.eggs/
lib/
lib64/
parts/
sdist/
var/
wheels/
*.egg-info/
.installed.cfg
*.egg

# Virtual environments
.venv/
venv/
ENV/
env/

# IDE
.vscode/
.idea/
*.swp
*.swo

# Testing
.pytest_cache/
.coverage
htmlcov/
.tox/

# Distribution / packaging
dist/
*.egg-info/
"@
                Set-Content -Path $gitignorePath -Value $gitignoreContent
            }

            # Create pyproject.toml or requirements.txt
            if ($UseUV -and (Test-CachedCommand 'uv')) {
                # Use uv to initialize project
                Push-Location $projectPath
                try {
                    & uv init --no-readme 2>&1 | Out-Null
                }
                finally {
                    Pop-Location
                }
            }
            else {
                # Create basic requirements.txt
                $requirementsPath = Join-Path $projectPath 'requirements.txt'
                if (-not (Test-Path -LiteralPath $requirementsPath)) {
                    Set-Content -Path $requirementsPath -Value "# Project dependencies`n"
                }
            }

            # Create main.py
            $mainPath = Join-Path $projectPath 'main.py'
            if (-not (Test-Path -LiteralPath $mainPath)) {
                $mainContent = @"
#!/usr/bin/env python3
"""
Main entry point for $Name
"""

def main():
    print("Hello, World!")


if __name__ == "__main__":
    main()
"@
                Set-Content -Path $mainPath -Value $mainContent
            }

            return $projectPath
        }
        catch {
            Write-Error "Failed to create Python project: $($_.Exception.Message)"
            return $null
        }
    }

    if (-not (Test-Path Function:\New-PythonProject -ErrorAction SilentlyContinue)) {
        Set-AgentModeFunction -Name 'New-PythonProject' -Body ${function:New-PythonProject}
    }

    # ===============================================
    # Install Python Package (unified)
    # ===============================================

    <#
    .SYNOPSIS
        Installs Python packages using the best available tool.

    .DESCRIPTION
        Installs Python packages using the best available tool in order of preference:
        - uv (if available) - fastest option
        - pip (if available) - standard option
        Falls back gracefully if neither is available.

    .PARAMETER Packages
        Package names to install.
        Can be used multiple times or as an array.

    .PARAMETER Arguments
        Additional arguments to pass to the installer.
        Can be used multiple times or as an array.

    .EXAMPLE
        Install-PythonPackage requests
        Installs requests using the best available tool.

    .EXAMPLE
        Install-PythonPackage pytest --dev
        Installs pytest as a dev dependency (uv only).

    .OUTPUTS
        System.String. Output from package installation.
    #>
    function Install-PythonPackage {
        [CmdletBinding()]
        [OutputType([string])]
        param(
            [Parameter(Mandatory, ValueFromRemainingArguments = $true)]
            [string[]]$Packages,

            [Parameter()]
            [string[]]$Arguments
        )

        # Prefer uv if available (fastest)
        if (Test-CachedCommand 'uv') {
            try {
                $cmdArgs = @('pip', 'install')
                if ($Arguments) {
                    $cmdArgs += $Arguments
                }
                $cmdArgs += $Packages
                $result = & uv @cmdArgs 2>&1
                return $result
            }
            catch {
                Write-Warning "Failed to install with uv: $($_.Exception.Message). Trying pip..."
            }
        }

        # Fallback to pip
        if (Test-CachedCommand 'pip') {
            try {
                $cmdArgs = @('install')
                if ($Arguments) {
                    $cmdArgs += $Arguments
                }
                $cmdArgs += $Packages
                $result = & pip @cmdArgs 2>&1
                return $result
            }
            catch {
                Write-Error "Failed to install with pip: $($_.Exception.Message)"
                return $null
            }
        }

        # No installer available
        $repoRoot = $null
        if (Get-Command Get-RepoRoot -ErrorAction SilentlyContinue) {
            try {
                $repoRoot = Get-RepoRoot -ScriptPath $PSScriptRoot -ErrorAction Stop
            }
            catch {
                $repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
            }
        }
        else {
            $repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
        }
        $installHint = if (Get-Command Get-ToolInstallHint -ErrorAction SilentlyContinue) {
            Get-ToolInstallHint -ToolName 'pip' -RepoRoot $repoRoot
        }
        else {
            "Install pip or uv: python -m ensurepip --upgrade (or scoop install uv)"
        }
        if (Get-Command Write-MissingToolWarning -ErrorAction SilentlyContinue) {
            Write-MissingToolWarning -Tool 'pip' -InstallHint $installHint
        }
        else {
            Write-Warning "Neither uv nor pip found. $installHint"
        }
        return $null
    }

    if (-not (Test-Path Function:\Install-PythonPackage -ErrorAction SilentlyContinue)) {
        Set-AgentModeFunction -Name 'Install-PythonPackage' -Body ${function:Install-PythonPackage}
    }
    if (-not (Get-Alias pyinstall -ErrorAction SilentlyContinue)) {
        if (Get-Command Set-AgentModeAlias -ErrorAction SilentlyContinue) {
            Set-AgentModeAlias -Name 'pyinstall' -Target 'Install-PythonPackage'
        }
        else {
            Set-Alias -Name 'pyinstall' -Value 'Install-PythonPackage' -ErrorAction SilentlyContinue
        }
    }

    # Mark fragment as loaded
    if (Get-Command Set-FragmentLoaded -ErrorAction SilentlyContinue) {
        Set-FragmentLoaded -FragmentName 'lang-python'
    }
}
catch {
    if (Get-Command Write-ProfileError -ErrorAction SilentlyContinue) {
        Write-ProfileError -FragmentName 'lang-python' -ErrorRecord $_
    }
    else {
        Write-Error "Failed to load lang-python fragment: $($_.Exception.Message)"
    }
}
