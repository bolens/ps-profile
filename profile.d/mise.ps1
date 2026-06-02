# ===============================================
# mise.ps1
# Mise (formerly rtx) runtime version management
# ===============================================

# Mise aliases and functions
# Requires: mise (https://mise.jdx.dev/)
# Tier: standard
# Dependencies: bootstrap, env

# Defensive check: ensure Test-CachedCommand is available (bootstrap must load first)
if ((Get-Command Test-CachedCommand -ErrorAction SilentlyContinue) -and (Test-CachedCommand mise)) {
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
    Set-AgentModeAlias -Name 'mise-outdated' -Target 'Test-MiseOutdated'
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
    Set-AgentModeAlias -Name 'mise-update' -Target 'Update-MiseRuntimes'
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
    Set-AgentModeAlias -Name 'mise-self-update' -Target 'Update-MiseSelf'
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
    Set-AgentModeAlias -Name 'mise-list' -Target 'Get-MiseRuntimes'
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
    Set-AgentModeAlias -Name 'mise-install' -Target 'Install-MiseRuntime'
    Set-AgentModeAlias -Name 'mise-add' -Target 'Install-MiseRuntime'
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
    Set-AgentModeAlias -Name 'mise-uninstall' -Target 'Remove-MiseRuntime'
    Set-AgentModeAlias -Name 'mise-remove' -Target 'Remove-MiseRuntime'
}
else {
    Invoke-MissingToolWarning -ToolName 'mise'
}
