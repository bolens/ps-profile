# ===============================================
# fzf.ps1
# fzf fuzzy finder helpers
# ===============================================
# Tier: essential
# Dependencies: bootstrap, env

<#
.SYNOPSIS
    fzf fuzzy finder helper functions and aliases.

.DESCRIPTION
    Provides PowerShell functions and aliases for fzf (fuzzy finder) operations.
    Functions check for fzf availability using Test-CachedCommand for efficient
    command detection without triggering module autoload.

.NOTES
    Module: PowerShell.Profile.Fzf
    Author: PowerShell Profile
#>

# ff: fuzzy-find files by name
<#
.SYNOPSIS
    Finds files using fzf fuzzy finder.

.DESCRIPTION
    Recursively searches for files and uses fzf to interactively select one.

.PARAMETER Pattern
    Optional pattern to filter files before passing to fzf.

.EXAMPLE
    Find-FileFuzzy

.EXAMPLE
    Find-FileFuzzy -Pattern "\.ps1$"
#>
function Find-FileFuzzy {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0)]
        [string]$Pattern = ''
    )
    
    if (Test-CachedCommand fzf) {
        if ($Pattern) {
            Get-ChildItem -Recurse -File | Where-Object { $_.Name -match $Pattern } | fzf
        }
        else {
            Get-ChildItem -Recurse -File | fzf
        }
    }
    else {
        Write-MissingToolWarning -Tool 'fzf' -InstallHint 'Install with: scoop install fzf'
    }
}

# fcmd: fuzzy-find a command
<#
.SYNOPSIS
    Finds PowerShell commands using fzf fuzzy finder.

.DESCRIPTION
    Lists all available commands and uses fzf to interactively select one.

.EXAMPLE
    Find-CommandFuzzy
#>
function Find-CommandFuzzy {
    [CmdletBinding()]
    param()
    
    if (Test-CachedCommand fzf) {
        Get-Command | Out-String | fzf
    }
    else {
        Write-MissingToolWarning -Tool 'fzf' -InstallHint 'Install with: scoop install fzf'
    }
}

# Create aliases for short forms
if (Get-Command -Name 'Set-AgentModeAlias' -ErrorAction SilentlyContinue) {
    Set-AgentModeAlias -Name 'ff' -Target 'Find-FileFuzzy'
    Set-AgentModeAlias -Name 'fcmd' -Target 'Find-CommandFuzzy'
}
else {
    Set-Alias -Name 'ff' -Value 'Find-FileFuzzy' -ErrorAction SilentlyContinue
    Set-Alias -Name 'fcmd' -Value 'Find-CommandFuzzy' -ErrorAction SilentlyContinue
}
