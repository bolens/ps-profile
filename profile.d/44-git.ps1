<#
profile.d/44-git.ps1

Contains Git helper functions and (optionally) completion registration.
#>

try {
    if ($null -ne (Get-Variable -Name 'GitHelpersLoaded' -Scope Global -ErrorAction SilentlyContinue)) { return }

    # Register Git helpers as lightweight stubs. They will call `git` at runtime
    # when invoked, and won't probe for `git` during dot-source.

    # Git current branch - get current branch name
    if (-not (Test-Path Function:Git-CurrentBranch -ErrorAction SilentlyContinue)) {
        Set-Item -Path Function:Git-CurrentBranch -Value { git rev-parse --abbrev-ref HEAD 2>$null } -Force | Out-Null
    }
    # Git status short - show concise status
    if (-not (Test-Path Function:Git-StatusShort -ErrorAction SilentlyContinue)) {
        Set-Item -Path Function:Git-StatusShort -Value { git status --porcelain 2>$null } -Force | Out-Null
    }
    # Git prompt segment - show current branch in prompt
    if (-not (Test-Path Function:Prompt-GitSegment -ErrorAction SilentlyContinue)) {
        Set-Item -Path Function:Prompt-GitSegment -Value { $b = (Git-CurrentBranch) -as [string]; if ($b) { return "($b)" }; return '' } -Force | Out-Null
    }

    Set-Variable -Name 'GitHelpersLoaded' -Value $true -Scope Global -Force
}
catch {
    if ($env:PS_PROFILE_DEBUG) { Write-Verbose "Git fragment failed: $($_.Exception.Message)" }
}
















