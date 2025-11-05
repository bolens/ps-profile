profile.d/24-container-utils.ps1
================================

Purpose
-------

Container engine helpers: report available engine and allow preference override

Usage
-----

See the fragment source: `24-container-utils.ps1` for examples and usage notes.

Functions
---------

- `Test-ContainerEngine` — Tests for available container engines and compose tools.
- `Set-ContainerEnginePreference` — Sets the preferred container engine for the session.

Dependencies
------------

None explicit; see the fragment for runtime checks and optional tooling dependencies.

Notes
-----

Keep this fragment idempotent and avoid heavy probes at dot-source. Prefer provider-first checks and lazy enablers like Enable-* helpers.
