# ===============================================
# rye.ps1
# Rye Python packaging and workflow tool
# ===============================================

# Rye aliases and functions
# Requires: rye (Rye - https://rye-up.com/)
# Tier: standard
# Dependencies: bootstrap, env

if (Test-CachedCommand rye) {
    # Rye add - add packages
    <#
    .SYNOPSIS
        Adds packages using Rye.
    .DESCRIPTION
        Adds packages to pyproject.toml. Supports --dev, --optional flags.
    .PARAMETER Packages
        Package names to add.
    .PARAMETER Dev
        Add as dev dependency (--dev).
    .PARAMETER Optional
        Add as optional dependency (--optional).
    .EXAMPLE
        Add-RyePackage requests
        Adds requests as production dependency.
    .EXAMPLE
        Add-RyePackage pytest -Dev
        Adds pytest as dev dependency.
    #>
    function Add-RyePackage {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory, ValueFromRemainingArguments = $true)]
            [string[]]$Packages,
            [switch]$Dev,
            [switch]$Optional
        )
        
        $args = @()
        if ($Dev) {
            $args += '--dev'
        }
        if ($Optional) {
            $args += '--optional'
        }
        & rye add @args @Packages
    }
    Set-AgentModeAlias -Name 'ryeadd' -Target 'Add-RyePackage'
    Set-AgentModeAlias -Name 'ryeinstall' -Target 'Add-RyePackage'
    # Rye remove - remove packages
    <#
    .SYNOPSIS
        Removes packages using Rye.
    .DESCRIPTION
        Removes packages from pyproject.toml. Supports --dev flag.
    .PARAMETER Packages
        Package names to remove.
    .PARAMETER Dev
        Remove from dev dependencies (--dev).
    .EXAMPLE
        Remove-RyePackage requests
        Removes requests from production dependencies.
    .EXAMPLE
        Remove-RyePackage pytest -Dev
        Removes pytest from dev dependencies.
    #>
    function Remove-RyePackage {
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
        & rye remove @args @Packages
    }
    Set-AgentModeAlias -Name 'ryeremove' -Target 'Remove-RyePackage'
    Set-AgentModeAlias -Name 'ryeuninstall' -Target 'Remove-RyePackage'
    # Rye sync - sync dependencies
    <#
    .SYNOPSIS
        Syncs dependencies using Rye.
    .DESCRIPTION
        Installs dependencies from pyproject.toml and updates lock file.
    .EXAMPLE
        Sync-RyeDependencies
        Syncs all dependencies.
    #>
    function Sync-RyeDependencies {
        [CmdletBinding()]
        param()
        
        & rye sync
    }
    Set-AgentModeAlias -Name 'ryesync' -Target 'Sync-RyeDependencies'
    # Rye update - update packages
    <#
    .SYNOPSIS
        Updates packages using Rye.
    .DESCRIPTION
        Updates specified packages or all packages if no arguments provided.
    .PARAMETER Packages
        Package names to update. Optional - updates all if omitted.
    .EXAMPLE
        Update-RyePackages
        Updates all packages.
    .EXAMPLE
        Update-RyePackages requests
        Updates requests package.
    #>
    function Update-RyePackages {
        [CmdletBinding()]
        param(
            [Parameter(ValueFromRemainingArguments = $true)]
            [string[]]$Packages
        )
        
        if ($Packages) {
            foreach ($package in $Packages) {
                & rye add --upgrade $package
            }
        }
        else {
            & rye sync --update-all
        }
    }
    Set-AgentModeAlias -Name 'ryeupdate' -Target 'Update-RyePackages'
}
else {
    Invoke-MissingToolWarning -ToolName 'rye' -ToolType 'python-package'
}
