# ===============================================
# pixi.ps1
# Package management with pixi
# ===============================================

# Pixi aliases
# Requires: pixi (https://github.com/prefix-dev/pixi)
# Tier: standard
# Dependencies: bootstrap, env

if (Test-CachedCommand pixi) {
    # Common pixi commands
    <#
    .SYNOPSIS
        Installs packages using pixi.
    .DESCRIPTION
        Adds packages to the pixi project environment.
    #>
    function Invoke-PixiInstall {
        param([string]$Package)
        pixi add $Package
    }
    Set-Alias -Name pxadd -Value Invoke-PixiInstall -Option AllScope -Force

    <#
    .SYNOPSIS
        Runs commands in the pixi environment.
    .DESCRIPTION
        Executes commands within the pixi-managed environment with all dependencies available.
    #>
    function Invoke-PixiRun {
        param([string]$Command, [string[]]$Args)
        pixi run $Command @Args
    }
    Set-Alias -Name pxrun -Value Invoke-PixiRun -Option AllScope -Force

    <#
    .SYNOPSIS
        Activates the pixi shell environment.
    .DESCRIPTION
        Starts a shell session with the pixi environment activated.
    #>
    function Invoke-PixiShell {
        pixi shell
    }
    Set-Alias -Name pxshell -Value Invoke-PixiShell -Option AllScope -Force

    # Pixi update - update packages
    <#
    .SYNOPSIS
        Updates pixi packages.
    .DESCRIPTION
        Updates all packages in the pixi environment to their latest versions.
    #>
    function Update-PixiPackages {
        [CmdletBinding()]
        param()
        
        & pixi update
    }
    Set-Alias -Name pixi-update -Value Update-PixiPackages -ErrorAction SilentlyContinue

    # Pixi list - list installed packages
    <#
    .SYNOPSIS
        Lists pixi packages.
    .DESCRIPTION
        Lists all packages installed in the pixi environment.
    #>
    function Get-PixiPackages {
        [CmdletBinding()]
        param()
        
        & pixi list
    }
    Set-Alias -Name pixi-list -Value Get-PixiPackages -ErrorAction SilentlyContinue

    # Pixi add - add packages
    <#
    .SYNOPSIS
        Adds packages to pixi project.
    .DESCRIPTION
        Adds packages to the pixi environment. Supports --channel flag.
    .PARAMETER Packages
        Package names to add.
    .PARAMETER Channel
        Channel to install from (--channel).
    .EXAMPLE
        Add-PixiPackage numpy
        Adds numpy to the project.
    .EXAMPLE
        Add-PixiPackage numpy -Channel conda-forge
        Adds numpy from conda-forge channel.
    #>
    function Add-PixiPackage {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory, ValueFromRemainingArguments = $true)]
            [string[]]$Packages,
            [string]$Channel
        )
        
        $args = @()
        if ($Channel) {
            $args += '--channel', $Channel
        }
        & pixi add @args @Packages
    }
    Set-Alias -Name pixi-add -Value Add-PixiPackage -ErrorAction SilentlyContinue

    # Pixi remove - remove packages
    <#
    .SYNOPSIS
        Removes packages from pixi project.
    .DESCRIPTION
        Removes packages from the pixi environment.
    .PARAMETER Packages
        Package names to remove.
    .EXAMPLE
        Remove-PixiPackage numpy
        Removes numpy from the project.
    #>
    function Remove-PixiPackage {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory, ValueFromRemainingArguments = $true)]
            [string[]]$Packages
        )
        
        & pixi remove @Packages
    }
    Set-Alias -Name pixi-remove -Value Remove-PixiPackage -ErrorAction SilentlyContinue
}
else {
    Write-MissingToolWarning -Tool 'pixi' -InstallHint 'Install with: scoop install pixi'
}
