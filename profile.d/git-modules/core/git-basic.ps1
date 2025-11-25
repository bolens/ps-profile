# ===============================================
# Basic Git command functions
# Status, add, commit, push, pull, log, diff, branch, checkout
# ===============================================

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

