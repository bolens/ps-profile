# ===============================================
# Advanced Git command functions
# Clone, stash, rebase, submodule, clean, sync, undo, default branch
# ===============================================

# Extras: register heavier helpers lazily so dot-sourcing this fragment remains cheap
$script:__GitHelpersInitialized = $false

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
        Set-AgentModeAlias -Name 'gcl' -Target 'Invoke-GitClone'
        $null = Set-AgentModeFunction -Name 'Save-GitStash' -Body { Invoke-GitCommand -Subcommand 'stash' -Arguments $args -CommandName 'git stash' } # Git stash - stash changes
        Set-AgentModeAlias -Name 'gsta' -Target 'Save-GitStash'
        $null = Set-AgentModeFunction -Name 'Restore-GitStash' -Body { Invoke-GitCommand -Subcommand 'stash' -Arguments @('pop') + $args -CommandName 'git stash pop' } # Git stash pop - apply stashed changes
        Set-AgentModeAlias -Name 'gstp' -Target 'Restore-GitStash'
        $null = Set-AgentModeFunction -Name 'Merge-GitRebase' -Body { Invoke-GitCommand -Subcommand 'rebase' -Arguments $args -CommandName 'git rebase' } # Git rebase - rebase commits
        Set-AgentModeAlias -Name 'gr' -Target 'Merge-GitRebase'
        $null = Set-AgentModeFunction -Name 'Continue-GitRebase' -Body { Invoke-GitCommand -Subcommand 'rebase' -Arguments @('--continue') -CommandName 'git rebase --continue' } # Git rebase continue - continue rebase
        Set-AgentModeAlias -Name 'grc' -Target 'Continue-GitRebase'
        $null = Set-AgentModeFunction -Name 'Update-GitSubmodule' -Body { Invoke-GitCommand -Subcommand 'submodule' -Arguments @('update', '--init', '--recursive') + $args -CommandName 'git submodule update' } # Git submodule update - update submodules
        Set-AgentModeAlias -Name 'gsub' -Target 'Update-GitSubmodule'
        $null = Set-AgentModeFunction -Name 'Clear-GitUntracked' -Body { Invoke-GitCommand -Subcommand 'clean' -Arguments @('-fdx') + $args -CommandName 'git clean' } # Git clean - remove untracked files
        Set-AgentModeAlias -Name 'gclean' -Target 'Clear-GitUntracked'
        $null = Set-AgentModeFunction -Name 'Set-LocationGitRoot' -Body { # Git cd to root - change to repository root
            $root = (& git rev-parse --show-toplevel) 2>$null
            if ($LASTEXITCODE -eq 0 -and $root) { Set-Location -LiteralPath $root } else { Write-Warning 'Not inside a git repository' }
        }
        Set-AgentModeAlias -Name 'cdg' -Target 'Set-LocationGitRoot'
        $null = Set-AgentModeFunction -Name 'Switch-GitPreviousBranch' -Body { Invoke-GitCommand -Subcommand 'checkout' -Arguments @('-') -CommandName 'git checkout -' } # Git checkout previous - switch to previous branch
        Set-AgentModeAlias -Name 'gob' -Target 'Switch-GitPreviousBranch'
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
        Set-AgentModeAlias -Name 'gprune' -Target 'Remove-GitMergedBranches'
        $null = Set-AgentModeFunction -Name 'Sync-GitRepository' -Body {
            if (-not (Test-GitRepositoryContext -CommandName 'git sync')) { return }

            Invoke-GitCommand -Subcommand 'fetch' -Arguments @('--prune') -CommandName 'git fetch --prune'
            Invoke-GitCommand -Subcommand 'rebase' -Arguments @('@{u}') -CommandName "git rebase @{u}"
        } # Git sync - fetch and rebase
        Set-AgentModeAlias -Name 'gsync' -Target 'Sync-GitRepository'
        $null = Set-AgentModeFunction -Name 'Undo-GitCommit' -Body { Invoke-GitCommand -Subcommand 'reset' -Arguments @('--soft', 'HEAD~1') -CommandName 'git reset --soft HEAD~1' } # Git undo - soft reset last commit
        Set-AgentModeAlias -Name 'gundo' -Target 'Undo-GitCommit'
        $null = Set-AgentModeFunction -Name 'Get-GitDefaultBranch' -Body { # Git default branch - get default branch name
            if (-not (Test-GitRepositoryContext -CommandName 'git default branch')) { return 'main' }

            $b = (git symbolic-ref refs/remotes/origin/HEAD 2>$null) -replace '^refs/remotes/origin/', ''
            if ($b) { $b } else { 'main' }
        }
        Set-AgentModeAlias -Name 'gdefault' -Target 'Get-GitDefaultBranch'
        # GitHub CLI helpers
        # Use Test-CachedCommand which handles caching and fallback internally
        $null = Set-AgentModeFunction -Name 'New-GitHubPullRequest' -Body { if (Test-CachedCommand gh) { gh pr create @args } else { Write-Warning 'GitHub CLI (gh) not found' } } # GitHub PR create - create a pull request
        Set-AgentModeAlias -Name 'prc' -Target 'New-GitHubPullRequest'
        $null = Set-AgentModeFunction -Name 'Show-GitHubPullRequest' -Body { if (Test-CachedCommand gh) { gh pr view --web @args } else { Write-Warning 'GitHub CLI (gh) not found' } } # GitHub PR view - view pull request in browser
        Set-AgentModeAlias -Name 'prv' -Target 'Show-GitHubPullRequest'
    }
}

# Register lazy stubs for the heavier Git helpers using Register-LazyFunction helper
# This reduces code duplication and makes the pattern more maintainable
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
# GitHub PR create - create a pull request
Register-LazyFunction -Name 'New-GitHubPullRequest' -Initializer { Ensure-GitHelper } -Alias 'prc'
# GitHub PR view - view pull request in browser
Register-LazyFunction -Name 'Show-GitHubPullRequest' -Initializer { Ensure-GitHelper } -Alias 'prv'

