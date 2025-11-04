profile.d/15-shortcuts.ps1
==========================

Purpose
-------
Small interactive shortcuts (editor, quick navigation, misc)

Usage
-----
See the fragment source: `15-shortcuts.ps1` for examples and usage notes.

Functions
---------
- `vsc` — >
- `project-root` — >

Dependencies
------------
None explicit; see the fragment for runtime checks and optional tooling dependencies.

Notes
-----
Keep this fragment idempotent and avoid heavy probes at dot-source. Prefer provider-first checks and lazy enablers like Enable-* helpers.
