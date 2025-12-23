# ===============================================
# Git helper utility functions
# Repository context checks and command wrapper
# ===============================================

<#
.SYNOPSIS
    Tests whether the current directory is a Git working tree.
.DESCRIPTION
    Confirms that the git executable is available and the current directory is inside a Git repository.
    Resets $LASTEXITCODE so callers do not inherit git errors.
.PARAMETER CommandName
    Friendly name for the caller, used in verbose skip messaging.
.OUTPUTS
    System.Boolean. Returns $true when the repository context is valid.
#>
function Test-GitRepositoryContext {
    param([string]$CommandName = 'git command')

    if (-not (Test-CachedCommand git)) {
        Write-Verbose "Skipping ${CommandName}: git command unavailable."
        return $false
    }

    $inside = git rev-parse --is-inside-work-tree 2>$null
    if ($LASTEXITCODE -ne 0 -or $inside -ne 'true') {
        Write-Verbose "Skipping ${CommandName}: not inside a git repository."
        $global:LASTEXITCODE = 0
        return $false
    }

    $global:LASTEXITCODE = 0
    return $true
}

<#
.SYNOPSIS
    Checks whether the current Git repository has at least one commit.
.DESCRIPTION
    Calls `git show-ref --quiet HEAD` and resets $LASTEXITCODE so higher-level helpers stay quiet on empty repos.
.PARAMETER CommandName
    Friendly name for the caller, used in verbose skip messaging.
.OUTPUTS
    System.Boolean. Returns $true when the repository contains commits.
#>
function Test-GitRepositoryHasCommits {
    param([string]$CommandName = 'git command')

    $null = git show-ref --quiet HEAD 2>$null
    if ($LASTEXITCODE -eq 0) {
        $global:LASTEXITCODE = 0
        return $true
    }

    Write-Verbose "Skipping ${CommandName}: repository has no commits yet."
    $global:LASTEXITCODE = 0
    return $false
}

<#
.SYNOPSIS
    Invokes a Git subcommand with repository safety guards.
.DESCRIPTION
    Provides a central wrapper that optionally validates repository context and commit availability before
    forwarding execution to `git`. Prevents noisy failures when the profile runs outside a repo or against
    a freshly initialized repository.
.PARAMETER Subcommand
    The git subcommand to execute (for example, 'status' or 'pull').
.PARAMETER Arguments
    Additional arguments to pass to git. Defaults to an empty array.
.PARAMETER CommandName
    Friendly label for verbose/log messages. Defaults to "git <Subcommand>".
.PARAMETER SkipRepositoryCheck
    Skips the repository existence check when specified.
.PARAMETER RequiresCommit
    Requires that the repository contains commits before executing.
.EXAMPLE
    Invoke-GitCommand -Subcommand 'status' -Arguments @('--short')
    Runs `git status --short` if the current directory is a Git repository.
#>
function Invoke-GitCommand {
    param(
        [Parameter(Mandatory)]
        [string]$Subcommand,

        [object[]]$Arguments = @(),

        [string]$CommandName,

        [switch]$SkipRepositoryCheck,

        [switch]$RequiresCommit
    )

    if (-not $CommandName) {
        $CommandName = "git $Subcommand"
    }

    if (-not $SkipRepositoryCheck) {
        if (-not (Test-GitRepositoryContext -CommandName $CommandName)) { return }
    }

    if ($RequiresCommit) {
        if (-not (Test-GitRepositoryHasCommits -CommandName $CommandName)) { return }
    }

    if ($null -eq $Arguments) { $Arguments = @() }

    git $Subcommand @Arguments
}

