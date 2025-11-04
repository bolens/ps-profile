profile.d/63-gum.ps1
====================

Purpose
-------
Terminal UI helpers with gum

Usage
-----
See the fragment source: `63-gum.ps1` for examples and usage notes.

Functions
---------
- `Invoke-GumConfirm` — >
- `Invoke-GumChoose` — >
- `Invoke-GumInput` — >
- `Invoke-GumSpin` — >
- `Invoke-GumStyle` — >

Dependencies
------------
None explicit; see the fragment for runtime checks and optional tooling dependencies.

Notes
-----
Keep this fragment idempotent and avoid heavy probes at dot-source. Prefer provider-first checks and lazy enablers like Enable-* helpers.
