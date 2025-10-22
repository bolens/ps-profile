profile.d/05-scoop-completion.ps1
=================================

Purpose
-------
Idempotent import of Scoop completion helpers when available.

Usage
-----
See the fragment source: `05-scoop-completion.ps1` for examples and usage notes.

Dependencies
------------
None explicit; see the fragment for runtime checks and optional tooling dependencies.

Notes
-----
Keep this fragment idempotent and avoid heavy probes at dot-source. Prefer provider-first checks and lazy enablers like Enable-* helpers.
