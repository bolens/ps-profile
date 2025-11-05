profile.d/41-yarn.ps1
=====================

Purpose
-------
Yarn package manager helpers (guarded)

Usage
-----
See the fragment source: `41-yarn.ps1` for examples and usage notes.

Functions
---------
- `yarn` — Register Yarn helpers lazily. Avoid expensive Get-Command probes at dot-source.
- `yarn-add` — Register Yarn helpers lazily. Avoid expensive Get-Command probes at dot-source.
- `yarn-install` — Yarn install - install project dependencies

Dependencies
------------
None explicit; see the fragment for runtime checks and optional tooling dependencies.

Notes
-----
Keep this fragment idempotent and avoid heavy probes at dot-source. Prefer provider-first checks and lazy enablers like Enable-* helpers.
