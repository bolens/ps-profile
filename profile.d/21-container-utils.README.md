profile.d/21-container-utils.ps1
================================

Purpose
-------
Container engine helpers: report available engine and allow preference override

Usage
-----
See the fragment source: `21-container-utils.ps1` for examples and usage notes.

Functions
---------
- `Test-ContainerEngine` — Container engine helpers: report available engine and allow preference override
- `Set-ContainerEnginePreference`

Dependencies
------------
None explicit; see the fragment for runtime checks and optional tooling dependencies.

Notes
-----
Keep this fragment idempotent and avoid heavy probes at dot-source. Prefer provider-first checks and lazy enablers like Enable-* helpers.
