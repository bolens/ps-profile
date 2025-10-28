profile.d/60-local-overrides.ps1
================================

Purpose
-------
This file is intended for machine-specific tweaks and should be in the

Usage
-----
See the fragment source: `60-local-overrides.ps1` for examples and usage notes.

Dependencies
------------
None explicit; see the fragment for runtime checks and optional tooling dependencies.

Notes
-----
Keep this fragment idempotent and avoid heavy probes at dot-source. Prefer provider-first checks and lazy enablers like Enable-* helpers.

