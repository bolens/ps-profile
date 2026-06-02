# ===============================================
# lang-python-env.ps1
# Python runtime, virtual environments, and project scaffolding
# ===============================================
# Tier: standard
# Dependencies: bootstrap, env

<#
.SYNOPSIS
    Python runtime, virtual environments, and project scaffolding.

.DESCRIPTION
    Provides wrapper functions for Python development tools:
    - Invoke-PythonScript: Python interpreter wrapper (python3/python fallback)
    - New-PythonVirtualEnv: Create virtual environments (uv/venv fallback)
    - New-PythonProject: Scaffold a new Python project with boilerplate

.NOTES
    All functions gracefully degrade when tools are not installed.
#>

try {
    # Idempotency check: skip if already loaded
    if (Get-Command Test-FragmentLoaded -ErrorAction SilentlyContinue) {
        if (Test-FragmentLoaded -FragmentName 'lang-python-env') { return }
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
            Invoke-MissingToolWarning -ToolName 'python' -ToolType 'python-runtime'
            return $null
        }

        if (Get-Command Invoke-WithWideEvent -ErrorAction SilentlyContinue) {
            return Invoke-WithWideEvent -OperationName 'python.script.invoke' -Context @{
                script              = $Script
                has_additional_args = ($null -ne $Arguments)
                python_command      = $pythonCmd
            } -ScriptBlock {
                $cmdArgs = @()
                if ($Script) {
                    $cmdArgs += $Script
                }
                if ($Arguments) {
                    $cmdArgs += $Arguments
                }
                & $pythonCmd @cmdArgs 2>&1
            }
        }
        else {
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
    }

    Set-AgentModeFunction -Name 'Invoke-PythonScript' -Body ${function:Invoke-PythonScript}
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
            if (Get-Command Invoke-WithWideEvent -ErrorAction SilentlyContinue) {
                return Invoke-WithWideEvent -OperationName 'python.venv.create' -Context @{
                    path           = $Path
                    python_version = $PythonVersion
                    python_command = $pythonCmd
                } -ScriptBlock {
                    & $pythonCmd -m venv $Path 2>&1
                }
            }
            else {
                try {
                    $result = & $pythonCmd -m venv $Path 2>&1
                    return $result
                }
                catch {
                    Write-Error "Failed to create venv with python: $($_.Exception.Message)"
                    return $null
                }
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
        Invoke-MissingToolWarning -ToolName 'python' -ToolType 'python-runtime'
        return $null
    }

    Set-AgentModeFunction -Name 'New-PythonVirtualEnv' -Body ${function:New-PythonVirtualEnv}
    if (-not (Get-Alias pyvenv -ErrorAction SilentlyContinue)) {
        if (Get-Command Set-AgentModeAlias -ErrorAction SilentlyContinue) {
            Set-AgentModeAlias -Name 'pyvenv' -Target 'New-PythonVirtualEnv'
        }
        else {
            Set-AgentModeAlias -Name 'pyvenv' -Target 'New-PythonVirtualEnv'
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
                $readmeContent = @'
# {0}

Python project created with lang-python.ps1

## Setup

```bash
# Create virtual environment
python -m venv .venv

# Activate virtual environment
# Windows (PowerShell):
.venv\Scripts\Activate.ps1
# bash/zsh:
source .venv/bin/activate
# fish:
source .venv/bin/activate.fish

# Install dependencies
uv pip install -r requirements.txt
```

## Usage

```bash
python main.py
```
'@ -f $Name
                Set-Content -Path $readmePath -Value $readmeContent
            }

            # Create .gitignore
            $gitignorePath = Join-Path $projectPath '.gitignore'
            if (-not (Test-Path -LiteralPath $gitignorePath)) {
                $gitignoreContent = @'
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
'@
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
                $mainContent = @'
#!/usr/bin/env python3
"""
Main entry point for {0}
"""

def main():
    print("Hello, World!")


if __name__ == "__main__":
    main()
'@ -f $Name
                Set-Content -Path $mainPath -Value $mainContent
            }

            return $projectPath
        }
        catch {
            if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                Write-StructuredError -ErrorRecord $_ -OperationName 'python.project.create' -Context @{
                    project_name = $Name
                    project_path = $projectPath
                }
            }
            else {
                Write-Error "Failed to create Python project: $($_.Exception.Message)"
            }
            return $null
        }
    }

    Set-AgentModeFunction -Name 'New-PythonProject' -Body ${function:New-PythonProject}
    # Mark fragment as loaded
    if (Get-Command Set-FragmentLoaded -ErrorAction SilentlyContinue) {
        Set-FragmentLoaded -FragmentName 'lang-python-env'
    }
}
catch {
    if (Get-Command Write-ProfileError -ErrorAction SilentlyContinue) {
        Write-ProfileError -FragmentName 'lang-python-env' -ErrorRecord $_
    }
    else {
        Write-Error "Failed to load lang-python-env fragment: $($_.Exception.Message)"
    }
}
