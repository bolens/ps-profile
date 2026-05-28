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
    Set-AgentModeAlias -Name 'hatchenv' -Target 'New-HatchEnvironment'
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
    Set-AgentModeAlias -Name 'hatchbuild' -Target 'Build-HatchProject'
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
    Set-AgentModeAlias -Name 'hatchversion' -Target 'Get-HatchVersion'
}
else {
    Invoke-MissingToolWarning -ToolName 'hatch' -ToolType 'python-package'
}
