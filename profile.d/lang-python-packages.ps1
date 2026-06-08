# ===============================================
# lang-python-packages.ps1
# Python unified package installer
# ===============================================
# Tier: standard
# Dependencies: bootstrap, env

<#
.SYNOPSIS
    Python unified package installer.

.DESCRIPTION
    Provides wrapper functions for Python development tools:
    - Install-PythonPackage: Install packages via uv/pip/pipenv/poetry (best available)

.NOTES
    All functions gracefully degrade when tools are not installed.
#>

try {
    # Idempotency check: skip if already loaded
    if (Get-Command Test-FragmentLoaded -ErrorAction SilentlyContinue) {
        if (Test-FragmentLoaded -FragmentName 'lang-python-packages') { return }
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


    .OUTPUTS
        System.String. Output from package installation.

    .EXAMPLE
        Install-PythonPackage requests
        Installs requests using the best available tool.


    .EXAMPLE
        Install-PythonPackage pytest --dev
        Installs pytest as a dev dependency (uv only).
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
            if (Get-Command Invoke-WithWideEvent -ErrorAction SilentlyContinue) {
                return Invoke-WithWideEvent -OperationName 'python.pip.install' -Context @{
                    packages            = $Packages
                    has_additional_args = ($null -ne $Arguments)
                } -ScriptBlock {
                    $cmdArgs = @('install')
                    if ($Arguments) {
                        $cmdArgs += $Arguments
                    }
                    $cmdArgs += $Packages
                    & pip @cmdArgs 2>&1
                }
            }
            else {
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
        Invoke-MissingToolWarning -ToolName 'pip' -ToolType 'python-package'
        return $null
    }

    Set-AgentModeFunction -Name 'Install-PythonPackage' -Body ${function:Install-PythonPackage}
    if (-not (Get-Alias pyinstall -ErrorAction SilentlyContinue)) {
        if (Get-Command Set-AgentModeAlias -ErrorAction SilentlyContinue) {
            Set-AgentModeAlias -Name 'pyinstall' -Target 'Install-PythonPackage'
        }
        else {
            Set-AgentModeAlias -Name 'pyinstall' -Target 'Install-PythonPackage'
        }
    }

    # Mark fragment as loaded
    # Mark fragment as loaded
    if (Get-Command Set-FragmentLoaded -ErrorAction SilentlyContinue) {
        Set-FragmentLoaded -FragmentName 'lang-python-packages'
    }
}
catch {
    if (Get-Command Write-ProfileError -ErrorAction SilentlyContinue) {
        Write-ProfileError -FragmentName 'lang-python-packages' -ErrorRecord $_
    }
    else {
        Write-Error "Failed to load lang-python-packages fragment: $($_.Exception.Message)"
    }
}
