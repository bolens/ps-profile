profile.d/61-eza.ps1
====================

Purpose
-------
Modern ls replacement with eza

Usage
-----
See the fragment source: `61-eza.ps1` for examples and usage notes.

Functions
---------
- `Get-ChildItemEza` — Lists directory contents using eza.
- `Get-ChildItemEzaShort` — Lists directory contents using eza (short alias).
- `Get-ChildItemEzaLong` — Lists directory contents in long format using eza.
- `Get-ChildItemEzaAll` — Lists all directory contents including hidden files using eza.
- `Get-ChildItemEzaAllLong` — Lists all directory contents in long format using eza.
- `Get-ChildItemEzaTree` — Lists directory contents in tree format using eza.
- `Get-ChildItemEzaTreeAll` — Lists all directory contents in tree format using eza.
- `Get-ChildItemEzaGit` — Lists directory contents with git status using eza.
- `Get-ChildItemEzaLongGit` — Lists directory contents in long format with git status using eza.
- `Get-ChildItemEzaBySize` — Lists directory contents sorted by size using eza.
- `Get-ChildItemEzaByTime` — Lists directory contents sorted by modification time using eza.

Aliases
-------
- `ls` — Lists directory contents using eza. (alias for `Get-ChildItemEza`)
- `l` — Lists directory contents using eza (short alias). (alias for `Get-ChildItemEzaShort`)
- `ll` — Lists directory contents in long format using eza. (alias for `Get-ChildItemEzaLong`)
- `la` — Lists all directory contents including hidden files using eza. (alias for `Get-ChildItemEzaAll`)
- `lla` — Lists all directory contents in long format using eza. (alias for `Get-ChildItemEzaAllLong`)
- `lt` — Lists directory contents in tree format using eza. (alias for `Get-ChildItemEzaTree`)
- `lta` — Lists all directory contents in tree format using eza. (alias for `Get-ChildItemEzaTreeAll`)
- `lg` — Lists directory contents with git status using eza. (alias for `Get-ChildItemEzaGit`)
- `llg` — Lists directory contents in long format with git status using eza. (alias for `Get-ChildItemEzaLongGit`)
- `ltime` — Lists directory contents sorted by modification time using eza. (alias for `Get-ChildItemEzaByTime`)

Dependencies
------------
None explicit; see the fragment for runtime checks and optional tooling dependencies.

Notes
-----
Keep this fragment idempotent and avoid heavy probes at dot-source. Prefer provider-first checks and lazy enablers like Enable-* helpers.
