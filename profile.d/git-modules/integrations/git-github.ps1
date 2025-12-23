# ===============================================
# GitHub CLI helper functions
# GitHub pull request operations
# ===============================================

# GitHub CLI helpers
# Use Test-CachedCommand which handles caching and fallback internally
if (-not (Test-Path Function:New-GitHubPullRequest)) {
    <#
    .SYNOPSIS
        Creates a GitHub pull request.
    .DESCRIPTION
        Creates a new pull request using the GitHub CLI (gh). Forwards all arguments to gh pr create.
    #>
    function New-GitHubPullRequest {
        param([Parameter(ValueFromRemainingArguments = $true)] $a)
        if (Test-CachedCommand gh) {
            gh pr create @a
        }
        else {
            Write-Warning 'GitHub CLI (gh) not found'
        }
    }
    Set-Alias -Name prc -Value New-GitHubPullRequest -ErrorAction SilentlyContinue
}

if (-not (Test-Path Function:Show-GitHubPullRequest)) {
    <#
    .SYNOPSIS
        Views a GitHub pull request in the browser.
    .DESCRIPTION
        Opens a pull request in the default browser using the GitHub CLI (gh). Forwards all arguments to gh pr view --web.
    #>
    function Show-GitHubPullRequest {
        param([Parameter(ValueFromRemainingArguments = $true)] $a)
        if (Test-CachedCommand gh) {
            gh pr view --web @a
        }
        else {
            Write-Warning 'GitHub CLI (gh) not found'
        }
    }
    Set-Alias -Name prv -Value Show-GitHubPullRequest -ErrorAction SilentlyContinue
}

