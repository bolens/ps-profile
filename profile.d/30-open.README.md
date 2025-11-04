profile.d/30-open.ps1
=====================

Purpose
-------
Cross-platform 'open' helper

Usage
-----
See the fragment source: `30-open.ps1` for examples and usage notes.

Functions
---------
- `open` — >

Dependencies
------------
None explicit; see the fragment for runtime checks and optional tooling dependencies.

Notes
-----
Keep this fragment idempotent and avoid heavy probes at dot-source. Prefer provider-first checks and lazy enablers like Enable-* helpers.
