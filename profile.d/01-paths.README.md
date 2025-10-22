profile.d/01-paths.ps1
======================

Purpose
-------
Normalize PATH and add common developer tool directories safely and idempotently.

Usage
-----
See the fragment source: `01-paths.ps1` for examples and usage notes.

Dependencies
------------
None explicit; see the fragment for runtime checks and optional tooling dependencies.

Notes
-----
Keep this fragment idempotent and avoid heavy probes at dot-source. Prefer provider-first checks and lazy enablers like Enable-* helpers.
