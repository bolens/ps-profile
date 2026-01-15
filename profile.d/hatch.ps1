# ===============================================
# hatch.ps1
# Hatch Python project manager
# ===============================================

# Hatch aliases and functions
# Requires: hatch (Hatch - https://hatch.pypa.io/)
# Tier: standard
# Dependencies: bootstrap, env

# Defensive check: ensure Test-CachedCommand is available (bootstrap must load first)
if ((Get-Command Test-CachedCommand -ErrorAction SilentlyContinue) -and (Test-CachedCommand hatch)) {
    # Hatch env create - create virtual environment
    <#
    .SYNOPSIS
        Creates a virtual environment using Hatch.
    .DESCRIPTION
        Creates a virtual environment for the project.
    .PARAMETER Name
        Environment name (optional).
    .EXAMPLE
        New-HatchEnvironment
        Creates default environment.
    .EXAMPLE
        New-HatchEnvironment -Name dev
        Creates named environment.
    #>
    function New-HatchEnvironment {
        [CmdletBinding()]
        param(
            [string]$Name
        )
        
        $args = @('env', 'create')
        if ($Name) {
            $args += $Name
        }
        & hatch @args
    }
    Set-Alias -Name hatchenv -Value New-HatchEnvironment -ErrorAction SilentlyContinue

    # Hatch build - build project
    <#
    .SYNOPSIS
        Builds the project using Hatch.
    .DESCRIPTION
        Builds distribution packages for the project.
    .EXAMPLE
        Build-HatchProject
        Builds the project.
    #>
    function Build-HatchProject {
        [CmdletBinding()]
        param()
        
        & hatch build
    }
    Set-Alias -Name hatchbuild -Value Build-HatchProject -ErrorAction SilentlyContinue

    # Hatch version - manage version
    <#
    .SYNOPSIS
        Gets or sets project version.
    .DESCRIPTION
        Shows or updates the project version.
    .PARAMETER Version
        Version to set (optional, shows current if omitted).
    .EXAMPLE
        Get-HatchVersion
        Shows current version.
    .EXAMPLE
        Set-HatchVersion -Version 1.2.3
        Sets version to 1.2.3.
    #>
    function Get-HatchVersion {
        [CmdletBinding()]
        param()
        
        & hatch version
    }
    function Set-HatchVersion {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory)]
            [string]$Version
        )
        
        & hatch version $Version
    }
    Set-Alias -Name hatchversion -Value Get-HatchVersion -ErrorAction SilentlyContinue
}
else {
    $installHint = if (Get-Command Get-PreferenceAwareInstallHint -ErrorAction SilentlyContinue) {
        Get-PreferenceAwareInstallHint -ToolName 'hatch' -ToolType 'python-package'
    }
    else {
        'Install with: scoop install hatch (or uv tool install hatch, or pip install hatch)'
    }
    Write-MissingToolWarning -Tool 'hatch' -InstallHint $installHint
}
