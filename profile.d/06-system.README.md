profile.d/06-system.ps1
=======================

Purpose
-------
System utilities (shell-like helpers adapted for PowerShell)

Usage
-----
See the fragment source: `06-system.ps1` for examples and usage notes.

Functions
---------
- `which` — System utilities (shell-like helpers adapted for PowerShell)
- `pgrep`
- `touch`
- `md`
- `del`
- `copy`
- `move`
- `search`
- `df`
- `htop`
- `ports` — Network tools
- `ptest`
- `dns`
- `rest`
- `web`
- `unzip` — Archive and editors
- `zip`
- `code`
- `vim`
- `vi`

Dependencies
------------
None explicit; see the fragment for runtime checks and optional tooling dependencies.

Notes
-----
Keep this fragment idempotent and avoid heavy probes at dot-source. Prefer provider-first checks and lazy enablers like Enable-* helpers.
