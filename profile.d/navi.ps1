# ===============================================
# navi.ps1
# Interactive cheatsheet tool
# ===============================================

# Navi aliases and functions
# Requires: navi (https://github.com/denisidoro/navi)
# Tier: standard
# Dependencies: bootstrap, env

if (Test-CachedCommand navi) {
    # Main navi command
    Set-Alias -Name cheats -Value navi -Option AllScope -Force

    # Quick search
    <#
    .SYNOPSIS
        Searches navi cheatsheets interactively.
    .DESCRIPTION
        Launches navi in interactive search mode. If a query is provided, pre-fills the search.
    #>
    function Invoke-NaviSearch {
        param([string]$Query)
        if ($Query) {
            navi --query $Query
        }
        else {
            navi
        }
    }
    Set-Alias -Name navis -Value Invoke-NaviSearch -Option AllScope -Force

    # Best match
    <#
    .SYNOPSIS
        Finds the best matching command from navi cheatsheets.
    .DESCRIPTION
        Searches navi cheatsheets and returns the best matching command. If a query is provided, uses it for searching.
    #>
    function Invoke-NaviBest {
        param([string]$Query)
        if ($Query) {
            navi --best --query $Query
        }
        else {
            navi --best
        }
    }
    Set-Alias -Name navib -Value Invoke-NaviBest -Option AllScope -Force

    # Print command without executing
    <#
    .SYNOPSIS
        Prints commands from navi cheatsheets without executing them.
    .DESCRIPTION
        Searches navi cheatsheets and prints the selected command without executing it. If a query is provided, uses it for searching.
    #>
    function Invoke-NaviPrint {
        param([string]$Query)
        if ($Query) {
            navi --print --query $Query
        }
        else {
            navi --print
        }
    }
    Set-Alias -Name navip -Value Invoke-NaviPrint -Option AllScope -Force
}
else {
    Write-MissingToolWarning -Tool 'navi' -InstallHint 'Install with: scoop install navi'
}
