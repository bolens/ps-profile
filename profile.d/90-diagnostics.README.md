profile.d/90-diagnostics.ps1
============================

Purpose
-------
Small diagnostics helpers that are only verbose when `PS_PROFILE_DEBUG` is

Usage
-----
See the fragment source: `90-diagnostics.ps1` for examples and usage notes.

Functions
---------
- `Show-ProfileDiagnostic` — Show profile diagnostics - PowerShell version, PATH, Podman status

Dependencies
------------
None explicit; see the fragment for runtime checks and optional tooling dependencies.

Notes
-----
Keep this fragment idempotent and avoid heavy probes at dot-source. Prefer provider-first checks and lazy enablers like Enable-* helpers.
