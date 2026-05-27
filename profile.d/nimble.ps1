# ===============================================
# nimble.ps1
# Nim package management
# ===============================================

# Nimble aliases and functions
# Requires: nimble (Nim package manager - https://nim-lang.org/)
# Tier: standard
# Dependencies: bootstrap, env

# Defensive check: ensure Test-CachedCommand is available (bootstrap must load first)
if ((Get-Command Test-CachedCommand -ErrorAction SilentlyContinue) -and (Test-CachedCommand nimble)) {
    # Nimble outdated - check for outdated packages
    <#
    .SYNOPSIS
        Checks for outdated Nim packages.
    .DESCRIPTION
        Lists all installed packages that have newer versions available.
        This is equivalent to running 'nimble outdated'.
    #>
    function Test-NimbleOutdated {
        [CmdletBinding()]
        param()
        
        & nimble outdated
    }
    Set-AgentModeAlias -Name 'nimble-outdated' -Target 'Test-NimbleOutdated'
    # Nimble update - update packages
    <#
    .SYNOPSIS
        Updates Nim packages.
    .DESCRIPTION
        Updates all installed packages to their latest versions.
    #>
    function Update-NimblePackages {
        [CmdletBinding()]
        param()
        
        & nimble update
    }
    Set-AgentModeAlias -Name 'nimble-update' -Target 'Update-NimblePackages'
    # Nimble install - install packages
    <#
    .SYNOPSIS
        Installs Nim packages.
    .DESCRIPTION
        Installs packages. Can install globally or locally (project-level).
    .PARAMETER Packages
        Package names to install.
    .PARAMETER Global
        Install globally (--global).
    .EXAMPLE
        Install-NimblePackage jester
        Installs jester locally (if in a project) or globally.
    .EXAMPLE
        Install-NimblePackage jester -Global
        Installs jester globally.
    #>
    function Install-NimblePackage {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory, ValueFromRemainingArguments = $true)]
            [string[]]$Packages,
            [switch]$Global
        )
        
        $args = @()
        if ($Global) {
            $args += '--global'
        }
        & nimble install @args @Packages
    }
    Set-AgentModeAlias -Name 'nimble-install' -Target 'Install-NimblePackage'
    Set-AgentModeAlias -Name 'nimble-add' -Target 'Install-NimblePackage'
    # Nimble uninstall - remove packages
    <#
    .SYNOPSIS
        Removes Nim packages.
    .DESCRIPTION
        Removes packages. Supports --global flag.
    .PARAMETER Packages
        Package names to remove.
    .PARAMETER Global
        Remove from global packages (--global).
    .EXAMPLE
        Remove-NimblePackage jester
        Removes jester from local installation.
    .EXAMPLE
        Remove-NimblePackage jester -Global
        Removes jester from global installation.
    #>
    function Remove-NimblePackage {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory, ValueFromRemainingArguments = $true)]
            [string[]]$Packages,
            [switch]$Global
        )
        
        $args = @()
        if ($Global) {
            $args += '--global'
        }
        & nimble uninstall @args @Packages
    }
    Set-AgentModeAlias -Name 'nimble-uninstall' -Target 'Remove-NimblePackage'
    Set-AgentModeAlias -Name 'nimble-remove' -Target 'Remove-NimblePackage'
}
else {
    Write-MissingToolWarning -Tool 'nimble' -InstallHint 'Install Nim from: https://nim-lang.org/install.html or use: scoop install nim'
}
