# ===============================================
# pipenv.ps1
# Pipenv Python package and environment management
# ===============================================

# Pipenv aliases and functions
# Requires: pipenv (Pipenv - https://pipenv.pypa.io/)
# Tier: standard
# Dependencies: bootstrap, env

if (Test-CachedCommand pipenv) {
    # Pipenv install - install packages
    <#
    .SYNOPSIS
        Installs packages using Pipenv.
    .DESCRIPTION
        Installs packages and adds them to Pipfile. Supports --dev flag.
    .PARAMETER Packages
        Package names to install.
    .PARAMETER Dev
        Install as dev dependency (--dev).
    .EXAMPLE
        Install-PipenvPackage requests
        Installs requests as production dependency.
    .EXAMPLE
        Install-PipenvPackage pytest -Dev
        Installs pytest as dev dependency.
    #>
    function Install-PipenvPackage {
        [CmdletBinding()]
        param(
            [Parameter(ValueFromRemainingArguments = $true)]
            [string[]]$Packages,
            [switch]$Dev
        )
        
        $args = @()
        if ($Dev) {
            $args += '--dev'
        }
        if ($Packages) {
            & pipenv install @args @Packages
        }
        else {
            & pipenv install @args
        }
    }
    Set-Alias -Name pipenvinstall -Value Install-PipenvPackage -ErrorAction SilentlyContinue
    Set-Alias -Name pipenvadd -Value Install-PipenvPackage -ErrorAction SilentlyContinue

    # Pipenv uninstall - remove packages
    <#
    .SYNOPSIS
        Removes packages using Pipenv.
    .DESCRIPTION
        Removes packages from Pipfile. Supports --dev flag.
    .PARAMETER Packages
        Package names to remove.
    .PARAMETER Dev
        Remove from dev dependencies (--dev).
    .EXAMPLE
        Remove-PipenvPackage requests
        Removes requests from production dependencies.
    .EXAMPLE
        Remove-PipenvPackage pytest -Dev
        Removes pytest from dev dependencies.
    #>
    function Remove-PipenvPackage {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory, ValueFromRemainingArguments = $true)]
            [string[]]$Packages,
            [switch]$Dev
        )
        
        $args = @()
        if ($Dev) {
            $args += '--dev'
        }
        & pipenv uninstall @args @Packages
    }
    Set-Alias -Name pipenvuninstall -Value Remove-PipenvPackage -ErrorAction SilentlyContinue
    Set-Alias -Name pipenvremove -Value Remove-PipenvPackage -ErrorAction SilentlyContinue

    # Pipenv update - update packages
    <#
    .SYNOPSIS
        Updates packages using Pipenv.
    .DESCRIPTION
        Updates specified packages or all packages if no arguments provided.
    .PARAMETER Packages
        Package names to update (optional, updates all if omitted).
    .EXAMPLE
        Update-PipenvPackages
        Updates all packages.
    .EXAMPLE
        Update-PipenvPackages requests
        Updates requests package.
    #>
    function Update-PipenvPackages {
        [CmdletBinding()]
        param(
            [Parameter(ValueFromRemainingArguments = $true)]
            [string[]]$Packages
        )
        
        if ($Packages) {
            & pipenv update @Packages
        }
        else {
            & pipenv update
        }
    }
    Set-Alias -Name pipenvupdate -Value Update-PipenvPackages -ErrorAction SilentlyContinue
}
else {
    $installHint = if (Get-Command Get-PreferenceAwareInstallHint -ErrorAction SilentlyContinue) {
        Get-PreferenceAwareInstallHint -ToolName 'pipenv' -ToolType 'python-package'
    }
    else {
        'Install with: scoop install pipenv (or uv tool install pipenv, or pip install pipenv)'
    }
    Write-MissingToolWarning -Tool 'pipenv' -InstallHint $installHint
}
