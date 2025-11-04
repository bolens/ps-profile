profile.d/01-env.ps1
====================

Purpose
-------
Set environment variable defaults in a safe, idempotent way. Do not

Usage
-----
See the fragment source: `01-env.ps1` for examples and usage notes.

Dependencies
------------
None explicit; see the fragment for runtime checks and optional tooling dependencies.

Notes
-----
Keep this fragment idempotent and avoid heavy probes at dot-source. Prefer provider-first checks and lazy enablers like Enable-* helpers.
