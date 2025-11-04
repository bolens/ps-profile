profile.d/25-lazydocker.ps1
===========================

Purpose
-------
lazydocker wrapper helpers

Usage
-----
See the fragment source: `25-lazydocker.ps1` for examples and usage notes.

Functions
---------
- `ld` — lazydocker wrapper helpers

Dependencies
------------
None explicit; see the fragment for runtime checks and optional tooling dependencies.

Notes
-----
Keep this fragment idempotent and avoid heavy probes at dot-source. Prefer provider-first checks and lazy enablers like Enable-* helpers.
