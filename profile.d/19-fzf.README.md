profile.d/19-fzf.ps1
====================

Purpose
-------
Lightweight fzf helpers (safe, idempotent)

Usage
-----
See the fragment source: `19-fzf.ps1` for examples and usage notes.

Functions
---------
- `ff` — ff: fuzzy-find files by name
- `fcmd` — fcmd: fuzzy-find a command

Dependencies
------------
None explicit; see the fragment for runtime checks and optional tooling dependencies.

Notes
-----
Keep this fragment idempotent and avoid heavy probes at dot-source. Prefer provider-first checks and lazy enablers like Enable-* helpers.

