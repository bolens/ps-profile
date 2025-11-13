# ===============================================
# 11-git.ps1
# Consolidated Git helpers
# =======================================

# Basic git shortcuts — simple stubs that forward all args to git.
# These helpers guard against common failure scenarios (missing repository,
# empty history) so profile diagnostics stay quiet in test environments.

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

    if (-not (Test-HasCommand git)) {
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

# Git status - show status
if (-not (Test-Path Function:Invoke-GitStatus)) {
    <#
    .SYNOPSIS
        Shows Git repository status.
    .DESCRIPTION
        Displays the working tree status, showing which files have changes, are staged, or are untracked. Forwards all arguments to git status.
    #>
    function Invoke-GitStatus {
        param([Parameter(ValueFromRemainingArguments = $true)] $a)
        Invoke-GitCommand -Subcommand 'status' -Arguments $a -CommandName 'git status'
    }
    Set-Alias -Name gs -Value Invoke-GitStatus -ErrorAction SilentlyContinue
}
# Git add - stage changes
if (-not (Test-Path Function:Add-GitChanges)) {
    <#
    .SYNOPSIS
        Stages changes for commit.
    .DESCRIPTION
        Adds file changes to the staging area for the next commit. Forwards all arguments to git add.
    #>
    function Add-GitChanges {
        param([Parameter(ValueFromRemainingArguments = $true)] $a)
        Invoke-GitCommand -Subcommand 'add' -Arguments $a -CommandName 'git add'
    }
    Set-Alias -Name ga -Value Add-GitChanges -ErrorAction SilentlyContinue
}
# Git commit - commit changes
if (-not (Test-Path Function:Save-GitCommit)) {
    <#
    .SYNOPSIS
        Commits staged changes.
    .DESCRIPTION
        Creates a new commit with the currently staged changes. Forwards all arguments to git commit.
    #>
    function Save-GitCommit {
        param([Parameter(ValueFromRemainingArguments = $true)] $a)
        Invoke-GitCommand -Subcommand 'commit' -Arguments $a -CommandName 'git commit'
    }
    Set-Alias -Name gc -Value Save-GitCommit -ErrorAction SilentlyContinue
}
# Git push - push to remote
if (-not (Test-Path Function:Publish-GitChanges)) {
    <#
    .SYNOPSIS
        Pushes commits to remote repository.
    .DESCRIPTION
        Uploads local commits to the remote repository. Forwards all arguments to git push.
    #>
    function Publish-GitChanges {
        param([Parameter(ValueFromRemainingArguments = $true)] $a)
        Invoke-GitCommand -Subcommand 'push' -Arguments $a -CommandName 'git push'
    }
    Set-Alias -Name gp -Value Publish-GitChanges -ErrorAction SilentlyContinue
}
# Git log - show commit log
if (-not (Test-Path Function:Get-GitLog)) {
    <#
    .SYNOPSIS
        Shows commit history.
    .DESCRIPTION
        Displays the commit log for the repository. Forwards all arguments to git log.
    #>
    function Get-GitLog {
        param([Parameter(ValueFromRemainingArguments = $true)] $a)
        Invoke-GitCommand -Subcommand 'log' -Arguments $a -CommandName 'git log' -RequiresCommit
    }
    Set-Alias -Name gl -Value Get-GitLog -Force
}
# Git diff - show changes
if (-not (Test-Path Function:Compare-GitChanges)) {
    <#
    .SYNOPSIS
        Shows differences between commits, branches, or working tree.
    .DESCRIPTION
        Displays changes between the working tree and staging area, or between commits. Forwards all arguments to git diff.
    #>
    function Compare-GitChanges {
        param([Parameter(ValueFromRemainingArguments = $true)] $a)
        Invoke-GitCommand -Subcommand 'diff' -Arguments $a -CommandName 'git diff'
    }
    Set-Alias -Name gd -Value Compare-GitChanges -ErrorAction SilentlyContinue
}
# Git branch - manage branches
if (-not (Test-Path Function:Get-GitBranch)) {
    <#
    .SYNOPSIS
        Lists, creates, or deletes branches.
    .DESCRIPTION
        Manages Git branches. Lists branches when called without arguments, or creates/deletes branches with arguments. Forwards all arguments to git branch.
    #>
    function Get-GitBranch {
        param([Parameter(ValueFromRemainingArguments = $true)] $a)
        Invoke-GitCommand -Subcommand 'branch' -Arguments $a -CommandName 'git branch'
    }
    Set-Alias -Name gb -Value Get-GitBranch -ErrorAction SilentlyContinue
}
# Git checkout - switch branches
if (-not (Test-Path Function:Switch-GitBranch)) {
    <#
    .SYNOPSIS
        Switches branches or restores working tree files.
    .DESCRIPTION
        Changes the active branch or restores files from a specific commit or branch. Forwards all arguments to git checkout.
    #>
    function Switch-GitBranch {
        param([Parameter(ValueFromRemainingArguments = $true)] $a)
        Invoke-GitCommand -Subcommand 'checkout' -Arguments $a -CommandName 'git checkout'
    }
    Set-Alias -Name gco -Value Switch-GitBranch -ErrorAction SilentlyContinue
}
# Git commit with message - commit changes with message
if (-not (Test-Path Function:Save-GitCommitWithMessage)) {
    <#
    .SYNOPSIS
        Commits staged changes with a message.
    .DESCRIPTION
        Creates a new commit with the currently staged changes and the provided commit message. Forwards all arguments to git commit (typically used with -m flag).
    #>
    function Save-GitCommitWithMessage {
        param([Parameter(ValueFromRemainingArguments = $true)] $a)
        Save-GitCommit @a
    }
    Set-Alias -Name gcm -Value Save-GitCommitWithMessage -ErrorAction SilentlyContinue
}
# Git pull - pull from remote
if (-not (Test-Path Function:Get-GitChanges)) {
    <#
    .SYNOPSIS
        Fetches and merges changes from remote repository.
    .DESCRIPTION
        Downloads changes from the remote repository and merges them into the current branch. Forwards all arguments to git pull.
    #>
    function Get-GitChanges {
        param([Parameter(ValueFromRemainingArguments = $true)] $a)
        Invoke-GitCommand -Subcommand 'pull' -Arguments $a -CommandName 'git pull'
    }
    Set-Alias -Name gpl -Value Get-GitChanges -ErrorAction SilentlyContinue
}
# Git fetch - fetch from remote
if (-not (Test-Path Function:Receive-GitChanges)) {
    <#
    .SYNOPSIS
        Downloads objects and refs from remote repository.
    .DESCRIPTION
        Fetches changes from the remote repository without merging them into the current branch. Forwards all arguments to git fetch.
    #>
    function Receive-GitChanges {
        param([Parameter(ValueFromRemainingArguments = $true)] $a)
        Invoke-GitCommand -Subcommand 'fetch' -Arguments $a -CommandName 'git fetch'
    }
    Set-Alias -Name gf -Value Receive-GitChanges -ErrorAction SilentlyContinue
}

# Extras: register heavier helpers lazily so dot-sourcing this fragment remains cheap
if (-not (Test-Path Function:Ensure-GitHelper)) {
    <#
    .SYNOPSIS
        Ensures Git helper functions are initialized.
    .DESCRIPTION
        Lazily initializes additional Git helper functions when first called.
        This keeps the initial profile loading fast by deferring heavier Git helpers.
    #>
    function Ensure-GitHelper {
        if ($script:__GitHelpersInitialized) { return }
        $script:__GitHelpersInitialized = $true
        if (-not (Test-Path Function:Set-AgentModeFunction)) { return }
        $null = Set-AgentModeFunction -Name 'Invoke-GitClone' -Body { Invoke-GitCommand -Subcommand 'clone' -Arguments $args -CommandName 'git clone' -SkipRepositoryCheck } # Git clone - clone a repository
        Set-Alias -Name gcl -Value Invoke-GitClone -ErrorAction SilentlyContinue
        $null = Set-AgentModeFunction -Name 'Save-GitStash' -Body { Invoke-GitCommand -Subcommand 'stash' -Arguments $args -CommandName 'git stash' } # Git stash - stash changes
        Set-Alias -Name gsta -Value Save-GitStash -ErrorAction SilentlyContinue
        $null = Set-AgentModeFunction -Name 'Restore-GitStash' -Body { Invoke-GitCommand -Subcommand 'stash' -Arguments @('pop') + $args -CommandName 'git stash pop' } # Git stash pop - apply stashed changes
        Set-Alias -Name gstp -Value Restore-GitStash -ErrorAction SilentlyContinue
        $null = Set-AgentModeFunction -Name 'Merge-GitRebase' -Body { Invoke-GitCommand -Subcommand 'rebase' -Arguments $args -CommandName 'git rebase' } # Git rebase - rebase commits
        Set-Alias -Name gr -Value Merge-GitRebase -ErrorAction SilentlyContinue
        $null = Set-AgentModeFunction -Name 'Continue-GitRebase' -Body { Invoke-GitCommand -Subcommand 'rebase' -Arguments @('--continue') -CommandName 'git rebase --continue' } # Git rebase continue - continue rebase
        Set-Alias -Name grc -Value Continue-GitRebase -ErrorAction SilentlyContinue
        $null = Set-AgentModeFunction -Name 'Update-GitSubmodule' -Body { Invoke-GitCommand -Subcommand 'submodule' -Arguments @('update', '--init', '--recursive') + $args -CommandName 'git submodule update' } # Git submodule update - update submodules
        Set-Alias -Name gsub -Value Update-GitSubmodule -ErrorAction SilentlyContinue
        $null = Set-AgentModeFunction -Name 'Clear-GitUntracked' -Body { Invoke-GitCommand -Subcommand 'clean' -Arguments @('-fdx') + $args -CommandName 'git clean' } # Git clean - remove untracked files
        Set-Alias -Name gclean -Value Clear-GitUntracked -ErrorAction SilentlyContinue
        $null = Set-AgentModeFunction -Name 'Set-LocationGitRoot' -Body { # Git cd to root - change to repository root
            $root = (& git rev-parse --show-toplevel) 2>$null
            if ($LASTEXITCODE -eq 0 -and $root) { Set-Location -LiteralPath $root } else { Write-Warning 'Not inside a git repository' }
        }
        Set-Alias -Name cdg -Value Set-LocationGitRoot -ErrorAction SilentlyContinue
        $null = Set-AgentModeFunction -Name 'Switch-GitPreviousBranch' -Body { Invoke-GitCommand -Subcommand 'checkout' -Arguments @('-') -CommandName 'git checkout -' } # Git checkout previous - switch to previous branch
        Set-Alias -Name gob -Value Switch-GitPreviousBranch -ErrorAction SilentlyContinue
        $null = Set-AgentModeFunction -Name 'Remove-GitMergedBranches' -Body { # Git prune merged - remove merged branches
            if (-not (Test-GitRepositoryContext -CommandName 'git prune merged')) { return }

            $up = (git rev-parse --abbrev-ref --symbolic-full-name '@{u=}') 2>$null
            if (-not $up) { Write-Warning 'No upstream set for this branch'; return }
            Invoke-GitCommand -Subcommand 'fetch' -Arguments @('--prune') -CommandName 'git fetch --prune'
            git branch --merged | ForEach-Object {
                $b = $_.Trim().TrimStart('*', ' ')
                if ($b -and $b -notin @('main', 'master', 'develop')) { git branch -D $b 2>$null | Out-Null }
            }
        }
        Set-Alias -Name gprune -Value Remove-GitMergedBranches -ErrorAction SilentlyContinue
        $null = Set-AgentModeFunction -Name 'Sync-GitRepository' -Body {
            if (-not (Test-GitRepositoryContext -CommandName 'git sync')) { return }

            Invoke-GitCommand -Subcommand 'fetch' -Arguments @('--prune') -CommandName 'git fetch --prune'
            Invoke-GitCommand -Subcommand 'rebase' -Arguments @('@{u}') -CommandName "git rebase @{u}"
        } # Git sync - fetch and rebase
        Set-Alias -Name gsync -Value Sync-GitRepository -ErrorAction SilentlyContinue
        $null = Set-AgentModeFunction -Name 'Undo-GitCommit' -Body { Invoke-GitCommand -Subcommand 'reset' -Arguments @('--soft', 'HEAD~1') -CommandName 'git reset --soft HEAD~1' } # Git undo - soft reset last commit
        Set-Alias -Name gundo -Value Undo-GitCommit -ErrorAction SilentlyContinue
        $null = Set-AgentModeFunction -Name 'Get-GitDefaultBranch' -Body { # Git default branch - get default branch name
            if (-not (Test-GitRepositoryContext -CommandName 'git default branch')) { return 'main' }

            $b = (git symbolic-ref refs/remotes/origin/HEAD 2>$null) -replace '^refs/remotes/origin/', ''
            if ($b) { $b } else { 'main' }
        }
        Set-Alias -Name gdefault -Value Get-GitDefaultBranch -ErrorAction SilentlyContinue

        # GitHub CLI helpers
        # Use Test-HasCommand which handles caching and fallback internally
        $null = Set-AgentModeFunction -Name 'New-GitHubPullRequest' -Body { if (Test-HasCommand gh) { gh pr create @args } else { Write-Warning 'GitHub CLI (gh) not found' } } # GitHub PR create - create a pull request
        Set-Alias -Name prc -Value New-GitHubPullRequest -ErrorAction SilentlyContinue
        $null = Set-AgentModeFunction -Name 'Show-GitHubPullRequest' -Body { if (Test-HasCommand gh) { gh pr view --web @args } else { Write-Warning 'GitHub CLI (gh) not found' } } # GitHub PR view - view pull request in browser
        Set-Alias -Name prv -Value Show-GitHubPullRequest -ErrorAction SilentlyContinue
    }
}

# Register lazy stubs for the heavier Git helpers using Register-LazyFunction helper
# This reduces code duplication and makes the pattern more maintainable
if (Test-Path Function:\Register-LazyFunction) {
    # Git clone - clone a repository
    Register-LazyFunction -Name 'Invoke-GitClone' -Initializer { Ensure-GitHelper } -Alias 'gcl'
    # Git stash - stash changes
    Register-LazyFunction -Name 'Save-GitStash' -Initializer { Ensure-GitHelper } -Alias 'gsta'
    # Git stash pop - apply stashed changes
    Register-LazyFunction -Name 'Restore-GitStash' -Initializer { Ensure-GitHelper } -Alias 'gstp'
    # Git rebase - rebase commits
    Register-LazyFunction -Name 'Merge-GitRebase' -Initializer { Ensure-GitHelper } -Alias 'gr'
    # Git rebase continue - continue rebase
    Register-LazyFunction -Name 'Continue-GitRebase' -Initializer { Ensure-GitHelper } -Alias 'grc'
    # Git submodule update - update submodules
    Register-LazyFunction -Name 'Update-GitSubmodule' -Initializer { Ensure-GitHelper } -Alias 'gsub'
    # Git clean - remove untracked files
    Register-LazyFunction -Name 'Clear-GitUntracked' -Initializer { Ensure-GitHelper } -Alias 'gclean'
    # Git cd to root - change to repository root
    Register-LazyFunction -Name 'Set-LocationGitRoot' -Initializer { Ensure-GitHelper } -Alias 'cdg'
    # Git checkout previous - switch to previous branch
    Register-LazyFunction -Name 'Switch-GitPreviousBranch' -Initializer { Ensure-GitHelper } -Alias 'gob'
    # Git prune merged - remove merged branches
    Register-LazyFunction -Name 'Remove-GitMergedBranches' -Initializer { Ensure-GitHelper } -Alias 'gprune'
    # Git sync - fetch and rebase
    Register-LazyFunction -Name 'Sync-GitRepository' -Initializer { Ensure-GitHelper } -Alias 'gsync'
    # Git undo - soft reset last commit
    Register-LazyFunction -Name 'Undo-GitCommit' -Initializer { Ensure-GitHelper } -Alias 'gundo'
    # Git default branch - get default branch name
    Register-LazyFunction -Name 'Get-GitDefaultBranch' -Initializer { Ensure-GitHelper } -Alias 'gdefault'
}
else {
    # Fallback to manual registration if Register-LazyFunction is not available
    # Git clone - clone a repository
    if (-not (Test-Path Function:Invoke-GitClone)) { Set-Item -Path Function:Invoke-GitClone -Value { Ensure-GitHelper; & (Get-Command Invoke-GitClone -CommandType Function).ScriptBlock.InvokeReturnAsIs($args) } -Force | Out-Null; Set-Alias -Name gcl -Value Invoke-GitClone -ErrorAction SilentlyContinue }
    # Git stash - stash changes
    if (-not (Test-Path Function:Save-GitStash)) { Set-Item -Path Function:Save-GitStash -Value { Ensure-GitHelper; & (Get-Command Save-GitStash -CommandType Function).ScriptBlock.InvokeReturnAsIs($args) } -Force | Out-Null; Set-Alias -Name gsta -Value Save-GitStash -ErrorAction SilentlyContinue }
    # Git stash pop - apply stashed changes
    if (-not (Test-Path Function:Restore-GitStash)) { Set-Item -Path Function:Restore-GitStash -Value { Ensure-GitHelper; & (Get-Command Restore-GitStash -CommandType Function).ScriptBlock.InvokeReturnAsIs($args) } -Force | Out-Null; Set-Alias -Name gstp -Value Restore-GitStash -ErrorAction SilentlyContinue }
    # Git rebase - rebase commits
    if (-not (Test-Path Function:Merge-GitRebase)) { Set-Item -Path Function:Merge-GitRebase -Value { Ensure-GitHelper; & (Get-Command Merge-GitRebase -CommandType Function).ScriptBlock.InvokeReturnAsIs($args) } -Force | Out-Null; Set-Alias -Name gr -Value Merge-GitRebase -ErrorAction SilentlyContinue }
    # Git rebase continue - continue rebase
    if (-not (Test-Path Function:Continue-GitRebase)) { Set-Item -Path Function:Continue-GitRebase -Value { Ensure-GitHelper; & (Get-Command Continue-GitRebase -CommandType Function).ScriptBlock.InvokeReturnAsIs($args) } -Force | Out-Null; Set-Alias -Name grc -Value Continue-GitRebase -ErrorAction SilentlyContinue }
    # Git submodule update - update submodules
    if (-not (Test-Path Function:Update-GitSubmodule)) { Set-Item -Path Function:Update-GitSubmodule -Value { Ensure-GitHelper; & (Get-Command Update-GitSubmodule -CommandType Function).ScriptBlock.InvokeReturnAsIs($args) } -Force | Out-Null; Set-Alias -Name gsub -Value Update-GitSubmodule -ErrorAction SilentlyContinue }
    # Git clean - remove untracked files
    if (-not (Test-Path Function:Clear-GitUntracked)) { Set-Item -Path Function:Clear-GitUntracked -Value { Ensure-GitHelper; & (Get-Command Clear-GitUntracked -CommandType Function).ScriptBlock.InvokeReturnAsIs($args) } -Force | Out-Null; Set-Alias -Name gclean -Value Clear-GitUntracked -ErrorAction SilentlyContinue }
    # Git cd to root - change to repository root
    if (-not (Test-Path Function:Set-LocationGitRoot)) { Set-Item -Path Function:Set-LocationGitRoot -Value { Ensure-GitHelper; & (Get-Command Set-LocationGitRoot -CommandType Function).ScriptBlock.InvokeReturnAsIs($args) } -Force | Out-Null; Set-Alias -Name cdg -Value Set-LocationGitRoot -ErrorAction SilentlyContinue }
    # Git checkout previous - switch to previous branch
    if (-not (Test-Path Function:Switch-GitPreviousBranch)) { Set-Item -Path Function:Switch-GitPreviousBranch -Value { Ensure-GitHelper; & (Get-Command Switch-GitPreviousBranch -CommandType Function).ScriptBlock.InvokeReturnAsIs($args) } -Force | Out-Null; Set-Alias -Name gob -Value Switch-GitPreviousBranch -ErrorAction SilentlyContinue }
    # Git prune merged - remove merged branches
    if (-not (Test-Path Function:Remove-GitMergedBranches)) { Set-Item -Path Function:Remove-GitMergedBranches -Value { Ensure-GitHelper; & (Get-Command Remove-GitMergedBranches -CommandType Function).ScriptBlock.InvokeReturnAsIs($args) } -Force | Out-Null; Set-Alias -Name gprune -Value Remove-GitMergedBranches -ErrorAction SilentlyContinue }
    # Git sync - fetch and rebase
    if (-not (Test-Path Function:Sync-GitRepository)) { Set-Item -Path Function:Sync-GitRepository -Value { Ensure-GitHelper; & (Get-Command Sync-GitRepository -CommandType Function).ScriptBlock.InvokeReturnAsIs($args) } -Force | Out-Null; Set-Alias -Name gsync -Value Sync-GitRepository -ErrorAction SilentlyContinue }
    # Git undo - soft reset last commit
    if (-not (Test-Path Function:Undo-GitCommit)) { Set-Item -Path Function:Undo-GitCommit -Value { Ensure-GitHelper; & (Get-Command Undo-GitCommit -CommandType Function).ScriptBlock.InvokeReturnAsIs($args) } -Force | Out-Null; Set-Alias -Name gundo -Value Undo-GitCommit -ErrorAction SilentlyContinue }
    # Git default branch - get default branch name
    if (-not (Test-Path Function:Get-GitDefaultBranch)) { Set-Item -Path Function:Get-GitDefaultBranch -Value { Ensure-GitHelper; & (Get-Command Get-GitDefaultBranch -CommandType Function).ScriptBlock.InvokeReturnAsIs($args) } -Force | Out-Null; Set-Alias -Name gdefault -Value Get-GitDefaultBranch -ErrorAction SilentlyContinue }
}
