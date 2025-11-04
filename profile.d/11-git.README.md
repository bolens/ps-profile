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
- `Ensure-GitHelper` — >
- `gs` — Git status - show status
- `ga` — Git add - stage changes
- `gc` — Git commit - commit changes
- `gp` — Git push - push to remote
- `gl` — Git log - show commit log
- `gd` — Git diff - show changes
- `gb` — Git branch - manage branches
- `gco` — Git checkout - switch branches
- `gcm` — Git commit with message - commit changes with message
- `gpl` — Git pull - pull from remote
- `gf` — Git fetch - fetch from remote
- `gcl` — Git clone - clone a repository
- `gsta` — Git stash - stash changes
- `gstp` — Git stash pop - apply stashed changes
- `gr` — Git rebase - rebase commits
- `grc` — Git rebase continue - continue rebase
- `gsub` — Git submodule update - update submodules
- `gclean` — Git clean - remove untracked files
- `cdg` — Git cd to root - change to repository root
- `gob` — Git checkout previous - switch to previous branch
- `gprune` — Git prune merged - remove merged branches
- `gsync` — Git sync - fetch and rebase
- `gundo` — Git undo - soft reset last commit
- `gdefault` — Git default branch - get default branch name
- `prc` — GitHub CLI helpers
- `prv` — GitHub PR view - view pull request in browser

Dependencies
------------
None explicit; see the fragment for runtime checks and optional tooling dependencies.

Notes
-----
Keep this fragment idempotent and avoid heavy probes at dot-source. Prefer provider-first checks and lazy enablers like Enable-* helpers.
