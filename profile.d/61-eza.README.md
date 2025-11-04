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
- `ls` — >
- `l` — >
- `ll` — >
- `la` — >
- `lla` — >
- `lt` — >
- `lta` — >
- `lg` — >
- `llg` — >
- `lS` — >
- `ltime` — >

Dependencies
------------
None explicit; see the fragment for runtime checks and optional tooling dependencies.

Notes
-----
Keep this fragment idempotent and avoid heavy probes at dot-source. Prefer provider-first checks and lazy enablers like Enable-* helpers.
