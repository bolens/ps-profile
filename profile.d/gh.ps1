# ===============================================
# gh.ps1
# GitHub CLI helpers
# ===============================================
# Tier: essential
# Dependencies: bootstrap, env

<#
.SYNOPSIS
    GitHub CLI helper functions and aliases.

.DESCRIPTION
    Provides PowerShell functions and aliases for common GitHub CLI operations.
    Functions check for gh availability using Test-HasCommand for efficient
    command detection without triggering module autoload.

.NOTES
    Module: PowerShell.Profile.GitHub
    Author: PowerShell Profile
#>

# GitHub open - open repository in web browser
<#
.SYNOPSIS
    Opens a GitHub repository in the web browser.

.DESCRIPTION
    Opens the current repository or a specified repository in the GitHub web interface.

.PARAMETER Repository
    Optional repository path (e.g., "owner/repo"). If not specified, opens the current repository.

.EXAMPLE
    Open-GitHubRepository

.EXAMPLE
    Open-GitHubRepository -Repository "microsoft/vscode"
#>
function Open-GitHubRepository {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0)]
        [string]$Repository
    )
    
    if (Test-CachedCommand gh) {
        if ($Repository) {
            gh repo view $Repository --web
        }
        else {
            gh repo view --web
        }
    }
    else {
        Write-MissingToolWarning -Tool 'gh' -InstallHint 'Install with: scoop install gh'
    }
}

# GitHub PR management - manage pull requests
<#
.SYNOPSIS
    Manages GitHub pull requests.

.DESCRIPTION
    Wrapper for GitHub CLI pull request commands.

.PARAMETER Arguments
    Arguments to pass to gh pr.

.EXAMPLE
    Invoke-GitHubPullRequest list

.EXAMPLE
    Invoke-GitHubPullRequest create --title "My PR"
#>
function Invoke-GitHubPullRequest {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]]$Arguments
    )
    
    if (Test-CachedCommand gh) {
        gh pr @Arguments
    }
    else {
        Write-MissingToolWarning -Tool 'gh' -InstallHint 'Install with: scoop install gh'
    }
}

# Create aliases for short forms
if (Get-Command -Name 'Set-AgentModeAlias' -ErrorAction SilentlyContinue) {
    Set-AgentModeAlias -Name 'gh-open' -Target 'Open-GitHubRepository'
    Set-AgentModeAlias -Name 'gh-pr' -Target 'Invoke-GitHubPullRequest'
}
else {
    Set-Alias -Name 'gh-open' -Value 'Open-GitHubRepository' -ErrorAction SilentlyContinue
    Set-Alias -Name 'gh-pr' -Value 'Invoke-GitHubPullRequest' -ErrorAction SilentlyContinue
}
