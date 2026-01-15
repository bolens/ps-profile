# ===============================================
# lazydocker.ps1
# lazydocker wrapper helpers
# ===============================================
# Tier: essential
# Dependencies: bootstrap, env

<#
.SYNOPSIS
    lazydocker helper functions and aliases.

.DESCRIPTION
    Provides PowerShell functions and aliases for lazydocker operations.
    Functions check for lazydocker availability using Test-CachedCommand for efficient
    command detection without triggering module autoload.

.NOTES
    Module: PowerShell.Profile.LazyDocker
    Author: PowerShell Profile
#>

# lazydocker - terminal UI for Docker
<#
.SYNOPSIS
    Launches lazydocker terminal UI.

.DESCRIPTION
    Wrapper function for lazydocker that checks for command availability before execution.

.PARAMETER Arguments
    Arguments to pass to lazydocker.

.EXAMPLE
    Invoke-LazyDocker

.EXAMPLE
    Invoke-LazyDocker --help
#>
function Invoke-LazyDocker {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]]$Arguments
    )
    
    if (Test-CachedCommand lazydocker) {
        lazydocker @Arguments
    }
    else {
        Write-MissingToolWarning -Tool 'lazydocker' -InstallHint 'Install with: scoop install lazydocker'
    }
}

# Create aliases for short forms
if (Get-Command -Name 'Set-AgentModeAlias' -ErrorAction SilentlyContinue) {
    Set-AgentModeAlias -Name 'ld' -Target 'Invoke-LazyDocker'
}
else {
    Set-Alias -Name 'ld' -Value 'Invoke-LazyDocker' -ErrorAction SilentlyContinue
}
