profile.d/10-wsl.ps1
====================

Purpose
-------
WSL helpers and shorthands

Usage
-----
See the fragment source: `10-wsl.ps1` for examples and usage notes.

Functions
---------
- `Stop-WSL` — Shuts down all WSL distributions.
- `Get-WSLDistribution` — Lists all WSL distributions with their status.
- `Start-UbuntuWSL` — Launches or switches to Ubuntu WSL distribution.

Aliases
-------
- `wsl-shutdown` — Shuts down all WSL distributions. (alias for `Stop-WSL`)
- `wsl-list` — Lists all WSL distributions with their status. (alias for `Get-WSLDistribution`)
- `ubuntu` — Launches or switches to Ubuntu WSL distribution. (alias for `Start-UbuntuWSL`)

Dependencies
------------
None explicit; see the fragment for runtime checks and optional tooling dependencies.

Notes
-----
Keep this fragment idempotent and avoid heavy probes at dot-source. Prefer provider-first checks and lazy enablers like Enable-* helpers.
