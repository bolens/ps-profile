profile.d/64-bottom.ps1
=======================

Purpose
-------
System monitor with bottom

Usage
-----
See the fragment source: `64-bottom.ps1` for examples and usage notes.

Aliases
-------
- `top` — Main bottom command (alias for `btm`)
- `htop` — alias for `btm`
- `monitor` — alias for `btm`

Dependencies
------------
None explicit; see the fragment for runtime checks and optional tooling dependencies.

Notes
-----
Keep this fragment idempotent and avoid heavy probes at dot-source. Prefer provider-first checks and lazy enablers like Enable-* helpers.
