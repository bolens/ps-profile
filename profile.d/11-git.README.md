profile.d/11-git.ps1
====================

Purpose
-------

Consolidated Git helpers

Usage
-----

See the fragment source: `11-git.ps1` for examples and usage notes.

Functions
---------

- `Invoke-GitStatus` — 11-git.ps1
- `Add-GitChanges` — Git add - stage changes
- `Save-GitCommit` — Git commit - commit changes
- `Publish-GitChanges` — Git push - push to remote
- `Get-GitLog` — Git log - show commit log
- `Compare-GitChanges` — Git diff - show changes
- `Get-GitBranch` — Git branch - manage branches
- `Switch-GitBranch` — Git checkout - switch branches
- `Save-GitCommitWithMessage` — Git commit with message - commit changes with message
- `Get-GitChanges` — Git pull - pull from remote
- `Receive-GitChanges` — Git fetch - fetch from remote
- `Ensure-GitHelper` — Ensures Git helper functions are initialized.
- `Invoke-GitClone` — Git clone - clone a repository
- `Save-GitStash` — Git stash - stash changes
- `Restore-GitStash` — Git stash pop - apply stashed changes
- `Merge-GitRebase` — Git rebase - rebase commits
- `Continue-GitRebase` — Git rebase continue - continue rebase
- `Update-GitSubmodule` — Git submodule update - update submodules
- `Clear-GitUntracked` — Git clean - remove untracked files
- `Set-LocationGitRoot` — Git cd to root - change to repository root
- `Switch-GitPreviousBranch` — Git checkout previous - switch to previous branch
- `Remove-GitMergedBranches` — Git prune merged - remove merged branches
- `Sync-GitRepository` — Git sync - fetch and rebase
- `Undo-GitCommit` — Git undo - soft reset last commit
- `Get-GitDefaultBranch` — Git default branch - get default branch name
- `New-GitHubPullRequest` — GitHub CLI helpers
- `Show-GitHubPullRequest` — GitHub PR view - view pull request in browser

Aliases
-------

- `gs` — 11-git.ps1 (alias for `Invoke-GitStatus`)
- `ga` — Git add - stage changes (alias for `Add-GitChanges`)
- `gc` — Git commit - commit changes (alias for `Save-GitCommit`)
- `gp` — Git push - push to remote (alias for `Publish-GitChanges`)
- `gl` — Git log - show commit log (alias for `Get-GitLog`)
- `gd` — Git diff - show changes (alias for `Compare-GitChanges`)
- `gb` — Git branch - manage branches (alias for `Get-GitBranch`)
- `gco` — Git checkout - switch branches (alias for `Switch-GitBranch`)
- `gcm` — Git commit with message - commit changes with message (alias for `Save-GitCommitWithMessage`)
- `gpl` — Git pull - pull from remote (alias for `Get-GitChanges`)
- `gf` — Git fetch - fetch from remote (alias for `Receive-GitChanges`)
- `gcl` — Git clone - clone a repository (alias for `Invoke-GitClone`)
- `gsta` — Git stash - stash changes (alias for `Save-GitStash`)
- `gstp` — Git stash pop - apply stashed changes (alias for `Restore-GitStash`)
- `gr` — Git rebase - rebase commits (alias for `Merge-GitRebase`)
- `grc` — Git rebase continue - continue rebase (alias for `Continue-GitRebase`)
- `gsub` — Git submodule update - update submodules (alias for `Update-GitSubmodule`)
- `gclean` — Git clean - remove untracked files (alias for `Clear-GitUntracked`)
- `cdg` — Git cd to root - change to repository root (alias for `Set-LocationGitRoot`)
- `gob` — Git checkout previous - switch to previous branch (alias for `Switch-GitPreviousBranch`)
- `gprune` — Git prune merged - remove merged branches (alias for `Remove-GitMergedBranches`)
- `gsync` — Git sync - fetch and rebase (alias for `Sync-GitRepository`)
- `gundo` — Git undo - soft reset last commit (alias for `Undo-GitCommit`)
- `gdefault` — Git default branch - get default branch name (alias for `Get-GitDefaultBranch`)
- `prc` — GitHub CLI helpers (alias for `New-GitHubPullRequest`)
- `prv` — GitHub PR view - view pull request in browser (alias for `Show-GitHubPullRequest`)

Dependencies
------------

None explicit; see the fragment for runtime checks and optional tooling dependencies.

Notes
-----

Keep this fragment idempotent and avoid heavy probes at dot-source. Prefer provider-first checks and lazy enablers like Enable-* helpers.
