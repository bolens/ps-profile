# ===============================================
# mix.ps1
# Elixir Mix package management
# ===============================================

# Mix aliases and functions
# Requires: mix (Elixir Mix - https://elixir-lang.org/)
# Tier: standard
# Dependencies: bootstrap, env

if (Test-CachedCommand mix) {
    # Mix deps outdated - check for outdated packages
    <#
    .SYNOPSIS
        Checks for outdated Elixir dependencies.
    .DESCRIPTION
        Lists all dependencies that have newer versions available.
        This is equivalent to running 'mix deps.outdated'.
    #>
    function Test-MixOutdated {
        [CmdletBinding()]
        param()
        
        & mix deps.outdated
    }
    Set-Alias -Name mix-outdated -Value Test-MixOutdated -ErrorAction SilentlyContinue

    # Mix deps update - update packages
    <#
    .SYNOPSIS
        Updates Elixir dependencies.
    .DESCRIPTION
        Updates all dependencies to their latest versions within version constraints.
    #>
    function Update-MixDependencies {
        [CmdletBinding()]
        param()
        
        & mix deps.update --all
    }
    Set-Alias -Name mix-update -Value Update-MixDependencies -ErrorAction SilentlyContinue

    # Mix deps.get - install dependencies
    <#
    .SYNOPSIS
        Installs Mix dependencies.
    .DESCRIPTION
        Installs dependencies defined in mix.exs.
        This is equivalent to running 'mix deps.get'.
    .EXAMPLE
        Install-MixDependencies
        Installs all dependencies.
    #>
    function Install-MixDependencies {
        [CmdletBinding()]
        param()
        
        & mix deps.get
    }
    Set-Alias -Name mix-install -Value Install-MixDependencies -ErrorAction SilentlyContinue

    # Mix deps.get - add dependencies (requires manual mix.exs editing)
    <#
    .SYNOPSIS
        Adds Mix dependencies.
    .DESCRIPTION
        Note: Mix dependencies are added by editing mix.exs.
        This function provides guidance and then runs mix deps.get.
    .PARAMETER Package
        Package name to add (e.g., 'phoenix').
    .PARAMETER Version
        Version requirement (e.g., '~> 1.7').
    .EXAMPLE
        Add-MixDependency -Package phoenix -Version '~> 1.7'
        Provides instructions for adding Phoenix dependency.
    #>
    function Add-MixDependency {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory)]
            [string]$Package,
            [string]$Version = '~> 0.1'
        )
        
        Write-Warning "Mix dependencies are added to mix.exs. Add to deps function:"
        if ($Version) {
            Write-Output "{:$Package, `"$Version`"}"
        }
        else {
            Write-Output "{:$Package}"
        }
        Write-Output "Then run: mix deps.get"
    }
    Set-Alias -Name mix-add -Value Add-MixDependency -ErrorAction SilentlyContinue

    # Mix deps.clean - remove dependencies (requires manual mix.exs editing)
    <#
    .SYNOPSIS
        Removes Mix dependencies.
    .DESCRIPTION
        Note: Mix dependencies are removed by editing mix.exs.
        This function provides guidance and cleans dependencies.
    .PARAMETER Package
        Package name to remove.
    .EXAMPLE
        Remove-MixDependency phoenix
        Provides instructions for removing Phoenix dependency.
    #>
    function Remove-MixDependency {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory)]
            [string]$Package
        )
        
        Write-Warning "Mix dependencies are removed from mix.exs. Remove:"
        Write-Output "{:$Package, ...}"
        Write-Output "Then run: mix deps.clean $Package && mix deps.get"
        & mix deps.clean $Package
    }
    Set-Alias -Name mix-remove -Value Remove-MixDependency -ErrorAction SilentlyContinue
}
else {
    $installHint = if (Get-Command Get-PreferenceAwareInstallHint -ErrorAction SilentlyContinue) {
        Get-PreferenceAwareInstallHint -ToolName 'mix' -ToolType 'elixir-package' -DefaultInstallCommand 'Install Elixir from: https://elixir-lang.org/install.html or use: scoop install elixir'
    }
    else {
        'Install Elixir from: https://elixir-lang.org/install.html or use: scoop install elixir'
    }
    Write-MissingToolWarning -Tool 'mix' -InstallHint $installHint
}
