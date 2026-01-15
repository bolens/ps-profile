# ===============================================
# rg.ps1
# ripgrep wrapper helpers
# ===============================================
# Tier: essential
# Dependencies: bootstrap, env

<#
.SYNOPSIS
    ripgrep helper functions and aliases.

.DESCRIPTION
    Provides PowerShell functions and aliases for ripgrep operations.
    Functions check for rg availability using Test-CachedCommand for efficient
    command detection without triggering module autoload.

.NOTES
    Module: PowerShell.Profile.Ripgrep
    Author: PowerShell Profile
#>

# ripgrep find - find text with ripgrep
<#
.SYNOPSIS
    Finds text using ripgrep with common options.

.DESCRIPTION
    Wrapper for ripgrep with line numbers, hidden files, and case-insensitive search enabled.

.PARAMETER Pattern
    Text pattern to search for.

.EXAMPLE
    Find-RipgrepText -Pattern "function"

.EXAMPLE
    Find-RipgrepText -Pattern "error"
#>
function Find-RipgrepText {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$Pattern
    )
    
    if (Test-CachedCommand rg) {
        rg --line-number --hidden -s $Pattern
    }
    else {
        Write-MissingToolWarning -Tool 'rg' -InstallHint 'Install with: scoop install ripgrep'
    }
}

# Create aliases for short forms
if (Get-Command -Name 'Set-AgentModeAlias' -ErrorAction SilentlyContinue) {
    Set-AgentModeAlias -Name 'rgf' -Target 'Find-RipgrepText'
}
else {
    Set-Alias -Name 'rgf' -Value 'Find-RipgrepText' -ErrorAction SilentlyContinue
}
