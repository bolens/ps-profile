profile.d/09-wsl.ps1
====================

Purpose
-------
WSL helpers and shorthands

Usage
-----
See the fragment source: `09-wsl.ps1` for examples and usage notes.

Functions
---------
- `wsl-shutdown` — WSL helpers and shorthands
- `wsl-list`
- `ubuntu`

Dependencies
------------
None explicit; see the fragment for runtime checks and optional tooling dependencies.

Notes
-----
Keep this fragment idempotent and avoid heavy probes at dot-source. Prefer provider-first checks and lazy enablers like Enable-* helpers.
