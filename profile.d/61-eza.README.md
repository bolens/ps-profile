# profile.d/61-eza.ps1
====================

Purpose
-------
Provides modern directory listing aliases using eza, a modern replacement for ls.

Usage
-----
See the fragment source: `61-eza.ps1` for examples and usage notes.

Functions
---------
- `ls` — eza (replaces ls)
- `l` — eza (short alias)
- `ll` — eza -l (long listing)
- `la` — eza -la (long listing with hidden)
- `lla` — eza -la (long listing with hidden)
- `lt` — eza --tree (tree view)
- `lta` — eza --tree -a (tree view with hidden)
- `lg` — eza --git (with git status)
- `llg` — eza -l --git (long with git status)
- `lS` — eza -l -s size (sorted by size)
- `ltime` — eza -l -s modified (sorted by time)

Dependencies
------------
- eza (install with: scoop install eza)

Notes
-----
Eza provides colorful, informative directory listings with git integration and tree views. If eza is not installed, a warning is shown.
