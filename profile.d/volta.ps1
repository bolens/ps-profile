# ===============================================
# volta.ps1
# Volta JavaScript tool manager
# ===============================================

# Volta aliases and functions
# Requires: volta (Volta - https://volta.sh/)
# Tier: standard
# Dependencies: bootstrap, env

if (Test-CachedCommand volta) {
    # Volta install - install tools
    <#
    .SYNOPSIS
        Installs Node.js, npm, or Yarn using Volta.
    .DESCRIPTION
        Installs and pins tools to your project. Supports version specification.
    .PARAMETER Tools
        Tool names with optional versions (e.g., node@18, npm@9, yarn@1.22).
    .EXAMPLE
        Install-VoltaTool node@18
        Installs and pins Node.js 18.
    .EXAMPLE
        Install-VoltaTool node@18 npm@9
        Installs Node.js 18 and npm 9.
    #>
    function Install-VoltaTool {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory, ValueFromRemainingArguments = $true)]
            [string[]]$Tools
        )
        
        & volta install @Tools
    }
    Set-Alias -Name voltainstall -Value Install-VoltaTool -ErrorAction SilentlyContinue
    Set-Alias -Name voltaadd -Value Install-VoltaTool -ErrorAction SilentlyContinue

    # Volta pin - pin tools in project
    <#
    .SYNOPSIS
        Pins tools to your project's package.json.
    .DESCRIPTION
        Pins the current tool versions to package.json.
    .PARAMETER Tools
        Tool names with optional versions.
    .EXAMPLE
        Pin-VoltaTool node@18
        Pins Node.js 18 to package.json.
    #>
    function Pin-VoltaTool {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory, ValueFromRemainingArguments = $true)]
            [string[]]$Tools
        )
        
        & volta pin @Tools
    }
    Set-Alias -Name voltapin -Value Pin-VoltaTool -ErrorAction SilentlyContinue

    # Volta list - list installed tools
    <#
    .SYNOPSIS
        Lists installed Volta tools.
    .DESCRIPTION
        Shows all installed Node.js, npm, and Yarn versions.
    #>
    function Get-VoltaTools {
        [CmdletBinding()]
        param()
        
        & volta list
    }
    Set-Alias -Name voltalist -Value Get-VoltaTools -ErrorAction SilentlyContinue

    # Volta uninstall - remove tools
    <#
    .SYNOPSIS
        Uninstalls tools from Volta.
    .DESCRIPTION
        Removes installed tool versions.
    .PARAMETER Tools
        Tool names with versions to uninstall.
    .EXAMPLE
        Remove-VoltaTool node@18
        Uninstalls Node.js 18.
    #>
    function Remove-VoltaTool {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory, ValueFromRemainingArguments = $true)]
            [string[]]$Tools
        )
        
        & volta uninstall @Tools
    }
    Set-Alias -Name voltauninstall -Value Remove-VoltaTool -ErrorAction SilentlyContinue
    Set-Alias -Name voltaremove -Value Remove-VoltaTool -ErrorAction SilentlyContinue

    # Volta upgrade - update Volta itself
    <#
    .SYNOPSIS
        Updates Volta to the latest version.
    .DESCRIPTION
        Updates Volta itself to the latest version.
    .EXAMPLE
        Update-VoltaSelf
        Updates Volta to the latest version.
    #>
    function Update-VoltaSelf {
        [CmdletBinding()]
        param()
        
        & volta upgrade
    }
    Set-Alias -Name voltaselfupdate -Value Update-VoltaSelf -ErrorAction SilentlyContinue
}
else {
    Write-MissingToolWarning -Tool 'volta' -InstallHint 'Install from: https://volta.sh/'
}
