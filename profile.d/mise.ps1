# ===============================================
# mise.ps1
# Mise (formerly rtx) runtime version management
# ===============================================

# Mise aliases and functions
# Requires: mise (https://mise.jdx.dev/)
# Tier: standard
# Dependencies: bootstrap, env

if (Test-CachedCommand mise) {
    # Mise outdated - check for outdated runtimes
    <#
    .SYNOPSIS
        Checks for outdated Mise runtimes.
    .DESCRIPTION
        Lists all installed runtimes that have newer versions available.
        This is equivalent to running 'mise outdated'.
    #>
    function Test-MiseOutdated {
        [CmdletBinding()]
        param()
        
        & mise outdated
    }
    Set-Alias -Name mise-outdated -Value Test-MiseOutdated -ErrorAction SilentlyContinue

    # Mise update - update runtimes
    <#
    .SYNOPSIS
        Updates Mise runtimes.
    .DESCRIPTION
        Updates all installed runtimes to their latest versions.
    #>
    function Update-MiseRuntimes {
        [CmdletBinding()]
        param()
        
        & mise update
    }
    Set-Alias -Name mise-update -Value Update-MiseRuntimes -ErrorAction SilentlyContinue

    # Mise self-update - update mise itself
    <#
    .SYNOPSIS
        Updates Mise to the latest version.
    .DESCRIPTION
        Updates Mise itself to the latest version.
    #>
    function Update-MiseSelf {
        [CmdletBinding()]
        param()
        
        & mise self-update
    }
    Set-Alias -Name mise-self-update -Value Update-MiseSelf -ErrorAction SilentlyContinue

    # Mise list - list installed runtimes
    <#
    .SYNOPSIS
        Lists installed Mise runtimes.
    .DESCRIPTION
        Lists all runtimes currently installed via Mise.
    #>
    function Get-MiseRuntimes {
        [CmdletBinding()]
        param()
        
        & mise list
    }
    Set-Alias -Name mise-list -Value Get-MiseRuntimes -ErrorAction SilentlyContinue

    # Mise install - install runtimes/tools
    <#
    .SYNOPSIS
        Installs Mise runtimes and tools.
    .DESCRIPTION
        Installs runtime versions or tools using mise install.
    .PARAMETER Runtimes
        Runtime names and versions to install (e.g., 'nodejs@20', 'python@3.11').
    .EXAMPLE
        Install-MiseRuntime nodejs@20
        Installs Node.js version 20.
    .EXAMPLE
        Install-MiseRuntime python@3.11,nodejs@20
        Installs multiple runtimes.
    #>
    function Install-MiseRuntime {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory, ValueFromRemainingArguments = $true)]
            [string[]]$Runtimes
        )
        
        & mise install @Runtimes
    }
    Set-Alias -Name mise-install -Value Install-MiseRuntime -ErrorAction SilentlyContinue
    Set-Alias -Name mise-add -Value Install-MiseRuntime -ErrorAction SilentlyContinue

    # Mise uninstall - remove runtimes/tools
    <#
    .SYNOPSIS
        Removes Mise runtimes and tools.
    .DESCRIPTION
        Uninstalls runtime versions or tools using mise uninstall.
    .PARAMETER Runtimes
        Runtime names and versions to remove (e.g., 'nodejs@20', 'python@3.11').
    .EXAMPLE
        Remove-MiseRuntime nodejs@20
        Removes Node.js version 20.
    #>
    function Remove-MiseRuntime {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory, ValueFromRemainingArguments = $true)]
            [string[]]$Runtimes
        )
        
        & mise uninstall @Runtimes
    }
    Set-Alias -Name mise-uninstall -Value Remove-MiseRuntime -ErrorAction SilentlyContinue
    Set-Alias -Name mise-remove -Value Remove-MiseRuntime -ErrorAction SilentlyContinue
}
else {
    Write-MissingToolWarning -Tool 'mise' -InstallHint 'Install with: scoop install mise or curl https://mise.run | sh'
}
