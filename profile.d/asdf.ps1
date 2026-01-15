# ===============================================
# asdf.ps1
# asdf version manager (multi-language)
# ===============================================

# asdf aliases and functions
# Requires: asdf (asdf - https://asdf-vm.com/)
# Tier: standard
# Dependencies: bootstrap, env

# Defensive check: ensure Test-CachedCommand is available (bootstrap must load first)
if ((Get-Command Test-CachedCommand -ErrorAction SilentlyContinue) -and (Test-CachedCommand asdf)) {
    # asdf install - install tools
    <#
    .SYNOPSIS
        Installs tools using asdf.
    .DESCRIPTION
        Installs tool versions. Supports version specification.
    .PARAMETER Tools
        Tool names with optional versions (e.g., nodejs 18.0.0, python 3.11).
    .EXAMPLE
        Install-AsdfTool nodejs 18.0.0
        Installs Node.js 18.0.0.
    .EXAMPLE
        Install-AsdfTool python 3.11
        Installs Python 3.11.
    #>
    function Install-AsdfTool {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory, ValueFromRemainingArguments = $true)]
            [string[]]$Tools
        )
        
        if ($Tools.Count -ge 2) {
            & asdf install $Tools[0] $Tools[1]
        }
        else {
            & asdf install $Tools[0]
        }
    }
    Set-Alias -Name asdfinstall -Value Install-AsdfTool -ErrorAction SilentlyContinue
    Set-Alias -Name asdfadd -Value Install-AsdfTool -ErrorAction SilentlyContinue

    # asdf list - list installed tools
    <#
    .SYNOPSIS
        Lists installed asdf tools.
    .DESCRIPTION
        Shows all installed tool versions.
    .PARAMETER Tool
        Tool name (optional, shows all if omitted).
    .EXAMPLE
        Get-AsdfTools
        Lists all installed tools.
    .EXAMPLE
        Get-AsdfTools nodejs
        Lists installed Node.js versions.
    #>
    function Get-AsdfTools {
        [CmdletBinding()]
        param(
            [string]$Tool
        )
        
        if ($Tool) {
            & asdf list $Tool
        }
        else {
            & asdf list
        }
    }
    Set-Alias -Name asdflist -Value Get-AsdfTools -ErrorAction SilentlyContinue

    # asdf uninstall - remove tools
    <#
    .SYNOPSIS
        Uninstalls tools from asdf.
    .DESCRIPTION
        Removes installed tool versions.
    .PARAMETER Tool
        Tool name.
    .PARAMETER Version
        Version to uninstall.
    .EXAMPLE
        Remove-AsdfTool nodejs 18.0.0
        Uninstalls Node.js 18.0.0.
    #>
    function Remove-AsdfTool {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory)]
            [string]$Tool,
            [Parameter(Mandatory)]
            [string]$Version
        )
        
        & asdf uninstall $Tool $Version
    }
    Set-Alias -Name asdfuninstall -Value Remove-AsdfTool -ErrorAction SilentlyContinue
    Set-Alias -Name asdfremove -Value Remove-AsdfTool -ErrorAction SilentlyContinue

    # asdf update - update asdf
    <#
    .SYNOPSIS
        Updates asdf to the latest version.
    .DESCRIPTION
        Updates asdf itself to the latest version.
    .EXAMPLE
        Update-AsdfSelf
        Updates asdf to the latest version.
    #>
    function Update-AsdfSelf {
        [CmdletBinding()]
        param()
        
        & asdf update
    }
    Set-Alias -Name asdfselfupdate -Value Update-AsdfSelf -ErrorAction SilentlyContinue
}
else {
    Write-MissingToolWarning -Tool 'asdf' -InstallHint 'Install from: https://asdf-vm.com/guide/getting-started.html'
}
