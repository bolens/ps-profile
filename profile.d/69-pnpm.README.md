profile.d/69-pnpm.ps1
=====================

Purpose
-------
Fast package manager with pnpm

Usage
-----
See the fragment source: `69-pnpm.ps1` for examples and usage notes.

Functions
---------
- `Invoke-PnpmInstall` — >
- `Invoke-PnpmDevInstall` — >
- `Invoke-PnpmRun` — >

Dependencies
------------
None explicit; see the fragment for runtime checks and optional tooling dependencies.

Notes
-----
Keep this fragment idempotent and avoid heavy probes at dot-source. Prefer provider-first checks and lazy enablers like Enable-* helpers.
