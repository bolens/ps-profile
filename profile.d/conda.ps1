# ===============================================
# conda.ps1
# Conda package and environment management
# ===============================================

# Conda aliases and functions
# Requires: conda (https://docs.conda.io/)
# Tier: standard
# Dependencies: bootstrap, env

if (Test-CachedCommand conda) {
    # Conda update all packages
    <#
    .SYNOPSIS
        Updates all packages in the current Conda environment.
    .DESCRIPTION
        Updates all packages in the current environment to their latest versions.
        This is equivalent to running 'conda update --all'.
    #>
    function Update-CondaPackages {
        [CmdletBinding()]
        param()
        
        & conda update --all -y
    }
    Set-Alias -Name conda-update -Value Update-CondaPackages -ErrorAction SilentlyContinue

    # Conda outdated - check for outdated packages
    <#
    .SYNOPSIS
        Checks for outdated Conda packages.
    .DESCRIPTION
        Lists all packages that have newer versions available.
        This is equivalent to running 'conda list --outdated'.
    #>
    function Test-CondaOutdated {
        [CmdletBinding()]
        param()
        
        & conda list --outdated
    }
    Set-Alias -Name conda-outdated -Value Test-CondaOutdated -ErrorAction SilentlyContinue

    # Conda self-update - update conda itself
    <#
    .SYNOPSIS
        Updates Conda to the latest version.
    .DESCRIPTION
        Updates Conda itself to the latest version using 'conda update conda'.
    #>
    function Update-CondaSelf {
        [CmdletBinding()]
        param()
        
        & conda update conda -y
    }
    Set-Alias -Name conda-self-update -Value Update-CondaSelf -ErrorAction SilentlyContinue

    # Conda install - install packages
    <#
    .SYNOPSIS
        Installs packages using conda.
    .DESCRIPTION
        Installs packages. Supports environment specification with -n/--name.
    .PARAMETER Packages
        Package names to install.
    .PARAMETER Environment
        Environment name to install into (-n/--name).
    .PARAMETER Channel
        Channel to install from (-c/--channel).
    .EXAMPLE
        Install-CondaPackage numpy
        Installs numpy in the current environment.
    .EXAMPLE
        Install-CondaPackage numpy -Environment myenv
        Installs numpy in the specified environment.
    #>
    function Install-CondaPackage {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory, ValueFromRemainingArguments = $true)]
            [string[]]$Packages,
            [string]$Environment,
            [string]$Channel
        )
        
        $args = @()
        if ($Environment) {
            $args += '-n', $Environment
        }
        if ($Channel) {
            $args += '-c', $Channel
        }
        $args += '-y'
        & conda install @args @Packages
    }
    Set-Alias -Name conda-install -Value Install-CondaPackage -ErrorAction SilentlyContinue
    Set-Alias -Name conda-add -Value Install-CondaPackage -ErrorAction SilentlyContinue

    # Conda remove - remove packages
    <#
    .SYNOPSIS
        Removes packages using conda.
    .DESCRIPTION
        Removes packages. Supports environment specification with -n/--name.
    .PARAMETER Packages
        Package names to remove.
    .PARAMETER Environment
        Environment name to remove from (-n/--name).
    .EXAMPLE
        Remove-CondaPackage numpy
        Removes numpy from the current environment.
    .EXAMPLE
        Remove-CondaPackage numpy -Environment myenv
        Removes numpy from the specified environment.
    #>
    function Remove-CondaPackage {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory, ValueFromRemainingArguments = $true)]
            [string[]]$Packages,
            [string]$Environment
        )
        
        $args = @()
        if ($Environment) {
            $args += '-n', $Environment
        }
        $args += '-y'
        & conda remove @args @Packages
    }
    Set-Alias -Name conda-remove -Value Remove-CondaPackage -ErrorAction SilentlyContinue
    Set-Alias -Name conda-uninstall -Value Remove-CondaPackage -ErrorAction SilentlyContinue
}
else {
    Write-MissingToolWarning -Tool 'conda' -InstallHint 'Install with: scoop install miniconda3 or download from https://docs.conda.io/en/latest/miniconda.html'
}
