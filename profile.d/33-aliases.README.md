profile.d/33-aliases.ps1
========================

Purpose
-------
Register user aliases and small interactive helper functions in an

Usage
-----
See the fragment source: `33-aliases.ps1` for examples and usage notes.

Functions
---------
- `ll` — List directory contents - enhanced ls
- `la` — List all directory contents - enhanced ls -a
- `Show-Path` — Show PATH entries as an array

Dependencies
------------
None explicit; see the fragment for runtime checks and optional tooling dependencies.

Notes
-----
Keep this fragment idempotent and avoid heavy probes at dot-source. Prefer provider-first checks and lazy enablers like Enable-* helpers.

