# ===============================================
# pdm.ps1
# PDM Python dependency manager
# ===============================================

# PDM aliases and functions
# Requires: pdm (PDM - https://pdm.fming.dev/)
# Tier: standard
# Dependencies: bootstrap, env

if (Test-CachedCommand pdm) {
    # PDM add - add packages
    <#
    .SYNOPSIS
        Adds packages using PDM.
    .DESCRIPTION
        Adds packages to pyproject.toml. Supports --dev, --group flags.
    .PARAMETER Packages
        Package names to add.
    .PARAMETER Dev
        Add as dev dependency (--dev).
    .PARAMETER Group
        Add to specific group (--group).
    .EXAMPLE
        Add-PdmPackage requests
        Adds requests as production dependency.
    .EXAMPLE
        Add-PdmPackage pytest -Dev
        Adds pytest as dev dependency.
    #>
    function Add-PdmPackage {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory, ValueFromRemainingArguments = $true)]
            [string[]]$Packages,
            [switch]$Dev,
            [string]$Group
        )
        
        $args = @()
        if ($Dev) {
            $args += '--dev'
        }
        if ($Group) {
            $args += '--group', $Group
        }
        & pdm add @args @Packages
    }
    Set-AgentModeAlias -Name 'pdmadd' -Target 'Add-PdmPackage'
    Set-AgentModeAlias -Name 'pdminstall' -Target 'Add-PdmPackage'
    # PDM remove - remove packages
    <#
    .SYNOPSIS
        Removes packages using PDM.
    .DESCRIPTION
        Removes packages from pyproject.toml. Supports --dev, --group flags.
    .PARAMETER Packages
        Package names to remove.
    .PARAMETER Dev
        Remove from dev dependencies (--dev).
    .PARAMETER Group
        Remove from specific group (--group).
    .EXAMPLE
        Remove-PdmPackage requests
        Removes requests from production dependencies.
    .EXAMPLE
        Remove-PdmPackage pytest -Dev
        Removes pytest from dev dependencies.
    #>
    function Remove-PdmPackage {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory, ValueFromRemainingArguments = $true)]
            [string[]]$Packages,
            [switch]$Dev,
            [string]$Group
        )
        
        $args = @()
        if ($Dev) {
            $args += '--dev'
        }
        if ($Group) {
            $args += '--group', $Group
        }
        & pdm remove @args @Packages
    }
    Set-AgentModeAlias -Name 'pdmremove' -Target 'Remove-PdmPackage'
    Set-AgentModeAlias -Name 'pdmuninstall' -Target 'Remove-PdmPackage'
    # PDM update - update packages
    <#
.SYNOPSIS
        Updates packages using PDM.
    .DESCRIPTION
        Updates specified packages or all packages if no arguments provided.
    .PARAMETER Packages
        Package names to update (optional, updates all if omitted).
    .EXAMPLE
    Update-PdmPackages -Packages 'package-name'
        Updates all packages.
    .EXAMPLE
        Update-PdmPackages requests
        Updates requests package.
#>
    function Update-PdmPackages {
        [CmdletBinding()]
        param(
            [Parameter(ValueFromRemainingArguments = $true)]
            [string[]]$Packages
        )
        
        if ($Packages) {
            & pdm update @Packages
        }
        else {
            & pdm update
        }
    }
    Set-AgentModeAlias -Name 'pdmupdate' -Target 'Update-PdmPackages'
}
else {
    Invoke-MissingToolWarning -ToolName 'pdm' -ToolType 'python-package'
}
