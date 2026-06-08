# ===============================================
# navi.ps1
# Interactive cheatsheet tool
# ===============================================

# Navi aliases and functions
# Requires: navi (https://github.com/denisidoro/navi)
# Tier: standard
# Dependencies: bootstrap, env

# Defensive check: ensure Test-CachedCommand is available (bootstrap must load first)
if ((Get-Command Test-CachedCommand -ErrorAction SilentlyContinue) -and (Test-CachedCommand navi)) {
    # Main navi command
    Set-Alias -Name cheats -Value navi -Option AllScope -Force

    # Quick search
    <#
.SYNOPSIS
        Searches navi cheatsheets interactively.
    .DESCRIPTION
        Launches navi in interactive search mode. If a query is provided, pre-fills the search.
.EXAMPLE
    Invoke-NaviSearch -Query 'docker'
.PARAMETER Query
    Optional search text to pre-fill the navi query prompt.

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
.EXAMPLE
    Invoke-NaviBest -Query 'find files'
.PARAMETER Query
    Optional search text used to select the best matching cheatsheet entry.

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
.EXAMPLE
    Invoke-NaviPrint -Query 'git rebase'
.PARAMETER Query
    Optional search text used when printing a cheatsheet command.

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
    Invoke-MissingToolWarning -ToolName 'navi'
}
