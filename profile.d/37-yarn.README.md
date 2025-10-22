profile.d/37-yarn.ps1
=====================

Purpose
-------
Yarn package manager helpers (guarded)

Usage
-----
See the fragment source: `37-yarn.ps1` for examples and usage notes.

Functions
---------
- `yarn` — Yarn execute - run yarn with arguments
- `yarn-add` — Yarn add - add packages to dependencies
- `yarn-install` — Yarn install - install project dependencies

Dependencies
------------
None explicit; see the fragment for runtime checks and optional tooling dependencies.

Notes
-----
Keep this fragment idempotent and avoid heavy probes at dot-source. Prefer provider-first checks and lazy enablers like Enable-* helpers.
