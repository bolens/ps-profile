profile.d/23-starship.ps1
=========================

Purpose
-------
Idempotent, quiet initialization of the Starship prompt for PowerShell.

Usage
-----
See the fragment source: `23-starship.ps1` for examples and usage notes.

Functions
---------
- `Initialize-Starship` — at the first prompt draw instead of at profile load.

Dependencies
------------
None explicit; see the fragment for runtime checks and optional tooling dependencies.

Notes
-----
Keep this fragment idempotent and avoid heavy probes at dot-source. Prefer provider-first checks and lazy enablers like Enable-* helpers.

