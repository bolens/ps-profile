profile.d/07-system.ps1
=======================

Purpose
-------
System utilities (shell-like helpers adapted for PowerShell)

Usage
-----
See the fragment source: `07-system.ps1` for examples and usage notes.

Functions
---------
- `which` — >
- `pgrep` — >
- `touch` — >
- `mkdir` — >
- `rm` — >
- `cp` — >
- `mv` — >
- `search` — >
- `df` — >
- `htop` — >
- `ports` — >
- `ptest` — >
- `dns` — >
- `rest` — >
- `web` — >
- `unzip` — >
- `zip` — >
- `code` — >
- `vim` — >
- `vi` — >

Dependencies
------------
None explicit; see the fragment for runtime checks and optional tooling dependencies.

Notes
-----
Keep this fragment idempotent and avoid heavy probes at dot-source. Prefer provider-first checks and lazy enablers like Enable-* helpers.
