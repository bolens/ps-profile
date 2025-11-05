profile.d/38-firebase.ps1
=========================

Purpose
-------
Firebase CLI helpers (guarded)

Usage
-----
See the fragment source: `38-firebase.ps1` for examples and usage notes.

Functions
---------
- `fb` — Register Firebase helpers lazily. Avoid expensive Get-Command probes at dot-source.
- `fb-deploy` — Register Firebase helpers lazily. Avoid expensive Get-Command probes at dot-source.
- `fb-serve` — Firebase serve - start local development server

Dependencies
------------
None explicit; see the fragment for runtime checks and optional tooling dependencies.

Notes
-----
Keep this fragment idempotent and avoid heavy probes at dot-source. Prefer provider-first checks and lazy enablers like Enable-* helpers.
