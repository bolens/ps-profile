profile.d/57-testing.ps1
========================

Purpose
-------
Testing frameworks helpers (guarded)

Usage
-----
See the fragment source: `57-testing.ps1` for examples and usage notes.

Functions
---------
- `jest` — Register testing framework helpers lazily. Avoid expensive Get-Command probes at dot-source.
- `vitest` — Vitest - next generation testing framework
- `playwright` — Playwright - end-to-end testing framework
- `cypress` — Cypress - JavaScript end-to-end testing framework
- `mocha` — Mocha - feature-rich JavaScript test framework

Dependencies
------------
None explicit; see the fragment for runtime checks and optional tooling dependencies.

Notes
-----
Keep this fragment idempotent and avoid heavy probes at dot-source. Prefer provider-first checks and lazy enablers like Enable-* helpers.
