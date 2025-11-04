<#
profile.d/44-git.ps1

Contains Git helper functions and (optionally) completion registration.
#>

try {
    if ($null -ne (Get-Variable -Name 'GitHelpersLoaded' -Scope Global -ErrorAction SilentlyContinue)) { return }

    # Register Git helpers as lightweight stubs. They will call `git` at runtime
    # when invoked, and won't probe for `git` during dot-source.

    # Git current branch - get current branch name
    if (-not (Test-Path Function:Get-GitCurrentBranch -ErrorAction SilentlyContinue)) {
        Set-Item -Path Function:Get-GitCurrentBranch -Value { git rev-parse --abbrev-ref HEAD 2>$null } -Force | Out-Null
        Set-Alias -Name Git-CurrentBranch -Value Get-GitCurrentBranch -ErrorAction SilentlyContinue
    }
    # Git status short - show concise status
    if (-not (Test-Path Function:Get-GitStatusShort -ErrorAction SilentlyContinue)) {
        Set-Item -Path Function:Get-GitStatusShort -Value { git status --porcelain 2>$null } -Force | Out-Null
        Set-Alias -Name Git-StatusShort -Value Get-GitStatusShort -ErrorAction SilentlyContinue
    }
    # Git prompt segment - show current branch in prompt
    if (-not (Test-Path Function:Format-PromptGitSegment -ErrorAction SilentlyContinue)) {
        Set-Item -Path Function:Format-PromptGitSegment -Value { $b = (Get-GitCurrentBranch) -as [string]; if ($b) { return "($b)" }; return '' } -Force | Out-Null
        Set-Alias -Name Prompt-GitSegment -Value Format-PromptGitSegment -ErrorAction SilentlyContinue
    }

    Set-Variable -Name 'GitHelpersLoaded' -Value $true -Scope Global -Force
}
catch {
    if ($env:PS_PROFILE_DEBUG) { Write-Verbose "Git fragment failed: $($_.Exception.Message)" }
}
