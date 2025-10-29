# ===============================================
# 62-navi.ps1
# Interactive cheatsheet tool
# ===============================================

# Navi aliases and functions
# Requires: navi (https://github.com/denisidoro/navi)

if (Get-Command navi -ErrorAction SilentlyContinue) {
    # Main navi command
    Set-Alias -Name cheats -Value navi -Option AllScope -Force

    # Quick search
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
    Write-Warning "navi not found. Install with: scoop install navi"
}









