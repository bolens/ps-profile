# ===============================================
# lang-python-pipx.ps1
# Python application manager (pipx)
# ===============================================
# Tier: standard
# Dependencies: bootstrap, env

<#
.SYNOPSIS
    Python application manager (pipx).

.DESCRIPTION
    Provides wrapper functions for Python development tools:
    - Install-PythonApp: Install Python applications via pipx
    - Invoke-Pipx: Run Python applications in isolated environments via pipx

.NOTES
    All functions gracefully degrade when tools are not installed.
#>

try {
    # Idempotency check: skip if already loaded
    if (Get-Command Test-FragmentLoaded -ErrorAction SilentlyContinue) {
        if (Test-FragmentLoaded -FragmentName 'lang-python-pipx') { return }
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
            Invoke-MissingToolWarning -ToolName 'pipx' -DefaultInstallCommand 'pip install pipx (or python -m pip install pipx)'
            return $null
        }

        if (Get-Command Invoke-WithWideEvent -ErrorAction SilentlyContinue) {
            return Invoke-WithWideEvent -OperationName 'python.pipx.install' -Context @{
                packages            = $Packages
                has_additional_args = ($null -ne $Arguments)
            } -ScriptBlock {
                $cmdArgs = @('install')
                if ($Arguments) {
                    $cmdArgs += $Arguments
                }
                $cmdArgs += $Packages
                & pipx @cmdArgs 2>&1
            }
        }
        else {
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
    }

    Set-AgentModeFunction -Name 'Install-PythonApp' -Body ${function:Install-PythonApp}
    if (-not (Get-Alias pipx-install -ErrorAction SilentlyContinue)) {
        if (Get-Command Set-AgentModeAlias -ErrorAction SilentlyContinue) {
            Set-AgentModeAlias -Name 'pipx-install' -Target 'Install-PythonApp'
        }
        else {
            Set-AgentModeAlias -Name 'pipx-install' -Target 'Install-PythonApp'
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
            Invoke-MissingToolWarning -ToolName 'pipx' -DefaultInstallCommand 'pip install pipx (or python -m pip install pipx)'
            return $null
        }

        if (Get-Command Invoke-WithWideEvent -ErrorAction SilentlyContinue) {
            return Invoke-WithWideEvent -OperationName 'python.pipx.run' -Context @{
                package             = $Package
                has_additional_args = ($null -ne $Arguments)
            } -ScriptBlock {
                $cmdArgs = @('run', $Package)
                if ($Arguments) {
                    $cmdArgs += $Arguments
                }
                & pipx @cmdArgs 2>&1
            }
        }
        else {
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
    }

    Set-AgentModeFunction -Name 'Invoke-Pipx' -Body ${function:Invoke-Pipx}
    if (-not (Get-Alias pipx -ErrorAction SilentlyContinue)) {
        if (Get-Command Set-AgentModeAlias -ErrorAction SilentlyContinue) {
            Set-AgentModeAlias -Name 'pipx' -Target 'Invoke-Pipx'
        }
        else {
            Set-AgentModeAlias -Name 'pipx' -Target 'Invoke-Pipx'
        }
    }

    # Mark fragment as loaded
    if (Get-Command Set-FragmentLoaded -ErrorAction SilentlyContinue) {
        Set-FragmentLoaded -FragmentName 'lang-python-pipx'
    }
}
catch {
    if (Get-Command Write-ProfileError -ErrorAction SilentlyContinue) {
        Write-ProfileError -FragmentName 'lang-python-pipx' -ErrorRecord $_
    }
    else {
        Write-Error "Failed to load lang-python-pipx fragment: $($_.Exception.Message)"
    }
}
