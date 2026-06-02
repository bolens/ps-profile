# ===============================================
# conda.ps1
# Conda package and environment management
# ===============================================

# Conda aliases and functions
# Requires: conda (https://docs.conda.io/)
# Tier: standard
# Dependencies: bootstrap, env

# Defensive check: ensure Test-CachedCommand is available (bootstrap must load first)
if ((Get-Command Test-CachedCommand -ErrorAction SilentlyContinue) -and (Test-CachedCommand conda)) {
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
    Set-AgentModeAlias -Name 'conda-update' -Target 'Update-CondaPackages'
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
    Set-AgentModeAlias -Name 'conda-outdated' -Target 'Test-CondaOutdated'
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
    Set-AgentModeAlias -Name 'conda-self-update' -Target 'Update-CondaSelf'
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
    Set-AgentModeAlias -Name 'conda-install' -Target 'Install-CondaPackage'
    Set-AgentModeAlias -Name 'conda-add' -Target 'Install-CondaPackage'
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
    Set-AgentModeAlias -Name 'conda-remove' -Target 'Remove-CondaPackage'
    Set-AgentModeAlias -Name 'conda-uninstall' -Target 'Remove-CondaPackage'
}
else {
    Invoke-MissingToolWarning -ToolName 'conda'
}
