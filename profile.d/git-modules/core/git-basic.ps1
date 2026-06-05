# ===============================================
# Basic Git command functions
# Status, add, commit, push, pull, log, diff, branch, checkout
# ===============================================

# Git status - show status
<#
.SYNOPSIS
    Shows Git repository status.
.DESCRIPTION
    Displays the working tree status, showing which files have changes, are staged, or are untracked. Forwards all arguments to git status.
#>
Set-AgentModeFunction -Name 'Invoke-GitStatus' -Body {
    param([Parameter(ValueFromRemainingArguments = $true)] $a)
    Invoke-GitCommand -Subcommand 'status' -Arguments $a -CommandName 'git status'
} | Out-Null
Set-AgentModeAlias -Name 'gs' -Target 'Invoke-GitStatus'

# Git add - stage changes
<#
.SYNOPSIS
    Stages changes for commit.
.DESCRIPTION
    Adds file changes to the staging area for the next commit. Forwards all arguments to git add.
#>
Set-AgentModeFunction -Name 'Add-GitChanges' -Body {
    param([Parameter(ValueFromRemainingArguments = $true)] $a)
    Invoke-GitCommand -Subcommand 'add' -Arguments $a -CommandName 'git add'
} | Out-Null
Set-AgentModeAlias -Name 'ga' -Target 'Add-GitChanges'

# Git commit - commit changes
<#
.SYNOPSIS
    Commits staged changes.
.DESCRIPTION
    Creates a new commit with the currently staged changes. Forwards all arguments to git commit.
#>
Set-AgentModeFunction -Name 'Save-GitCommit' -Body {
    param([Parameter(ValueFromRemainingArguments = $true)] $a)
    Invoke-GitCommand -Subcommand 'commit' -Arguments $a -CommandName 'git commit'
} | Out-Null
Set-AgentModeAlias -Name 'gc' -Target 'Save-GitCommit'

# Git push - push to remote
<#
.SYNOPSIS
    Pushes commits to remote repository.
.DESCRIPTION
    Uploads local commits to the remote repository. Forwards all arguments to git push.
#>
Set-AgentModeFunction -Name 'Publish-GitChanges' -Body {
    param([Parameter(ValueFromRemainingArguments = $true)] $a)
    Invoke-GitCommand -Subcommand 'push' -Arguments $a -CommandName 'git push'
} | Out-Null
Set-AgentModeAlias -Name 'gp' -Target 'Publish-GitChanges'

# Git log - show commit log
<#
.SYNOPSIS
    Shows commit history.
.DESCRIPTION
    Displays the commit log for the repository. Forwards all arguments to git log.
#>
Set-AgentModeFunction -Name 'Get-GitLog' -Body {
    param([Parameter(ValueFromRemainingArguments = $true)] $a)
    Invoke-GitCommand -Subcommand 'log' -Arguments $a -CommandName 'git log' -RequiresCommit
} | Out-Null
Set-AgentModeAlias -Name 'gl' -Target 'Get-GitLog'

# Git diff - show changes
<#
.SYNOPSIS
    Shows differences between commits, branches, or working tree.
.DESCRIPTION
    Displays changes between the working tree and staging area, or between commits. Forwards all arguments to git diff.
#>
Set-AgentModeFunction -Name 'Compare-GitChanges' -Body {
    param([Parameter(ValueFromRemainingArguments = $true)] $a)
    Invoke-GitCommand -Subcommand 'diff' -Arguments $a -CommandName 'git diff'
} | Out-Null
Set-AgentModeAlias -Name 'gd' -Target 'Compare-GitChanges'

# Git branch - manage branches
<#
.SYNOPSIS
    Lists, creates, or deletes branches.
.DESCRIPTION
    Manages Git branches. Lists branches when called without arguments, or creates/deletes branches with arguments. Forwards all arguments to git branch.
#>
Set-AgentModeFunction -Name 'Get-GitBranch' -Body {
    param([Parameter(ValueFromRemainingArguments = $true)] $a)
    Invoke-GitCommand -Subcommand 'branch' -Arguments $a -CommandName 'git branch'
} | Out-Null
Set-AgentModeAlias -Name 'gb' -Target 'Get-GitBranch'

# Git checkout - switch branches
<#
.SYNOPSIS
    Switches branches or restores working tree files.
.DESCRIPTION
    Changes the active branch or restores files from a specific commit or branch. Forwards all arguments to git checkout.
#>
Set-AgentModeFunction -Name 'Switch-GitBranch' -Body {
    param([Parameter(ValueFromRemainingArguments = $true)] $a)
    Invoke-GitCommand -Subcommand 'checkout' -Arguments $a -CommandName 'git checkout'
} | Out-Null
Set-AgentModeAlias -Name 'gco' -Target 'Switch-GitBranch'

# Git commit with message - commit changes with message
<#
.SYNOPSIS
    Commits staged changes with a message.
.DESCRIPTION
    Creates a new commit with the currently staged changes and the provided commit message. Forwards all arguments to git commit (typically used with -m flag).
#>
Set-AgentModeFunction -Name 'Save-GitCommitWithMessage' -Body {
    param([Parameter(ValueFromRemainingArguments = $true)] $a)
    Save-GitCommit @a
} | Out-Null
Set-AgentModeAlias -Name 'gcm' -Target 'Save-GitCommitWithMessage'

# Git pull - pull from remote
<#
.SYNOPSIS
    Fetches and merges changes from remote repository.
.DESCRIPTION
    Downloads changes from the remote repository and merges them into the current branch. Forwards all arguments to git pull.
#>
Set-AgentModeFunction -Name 'Get-GitChanges' -Body {
    param([Parameter(ValueFromRemainingArguments = $true)] $a)
    Invoke-GitCommand -Subcommand 'pull' -Arguments $a -CommandName 'git pull'
} | Out-Null
Set-AgentModeAlias -Name 'gpl' -Target 'Get-GitChanges'

# Git fetch - fetch from remote
<#
.SYNOPSIS
    Downloads objects and refs from remote repository.
.DESCRIPTION
    Fetches changes from the remote repository without merging them into the current branch. Forwards all arguments to git fetch.
#>
Set-AgentModeFunction -Name 'Receive-GitChanges' -Body {
    param([Parameter(ValueFromRemainingArguments = $true)] $a)
    Invoke-GitCommand -Subcommand 'fetch' -Arguments $a -CommandName 'git fetch'
} | Out-Null
Set-AgentModeAlias -Name 'gf' -Target 'Receive-GitChanges'
