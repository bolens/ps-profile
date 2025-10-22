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
- `which` — which equivalent
- `pgrep` — pgrep equivalent
- `touch` — touch equivalent
- `mkdir` — mkdir equivalent
- `rm` — rm equivalent
- `cp` — cp equivalent
- `mv` — mv equivalent
- `search` — search equivalent
- `df` — df equivalent
- `htop` — top equivalent
- `ports` — ports equivalent
- `ptest` — ptest equivalent
- `dns` — dns equivalent
- `rest` — rest equivalent
- `web` — web equivalent
- `unzip` — unzip equivalent
- `zip` — zip equivalent
- `code` — code alias for VS Code
- `vim` — vim alias for neovim
- `vi` — vi alias for neovim

Dependencies
------------
None explicit; see the fragment for runtime checks and optional tooling dependencies.

Notes
-----
Keep this fragment idempotent and avoid heavy probes at dot-source. Prefer provider-first checks and lazy enablers like Enable-* helpers.
