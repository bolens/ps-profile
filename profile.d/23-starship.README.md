profile.d/23-starship.ps1
=========================

Purpose
-------

Simple initialization of the Starship prompt for PowerShell.

Usage
-----

See the fragment source: `23-starship.ps1` for examples and usage notes.

Functions
---------

- `Initialize-Starship` — Initializes the Starship prompt for PowerShell.
- `global` — Fallback: manually create prompt function if init script fails
- `Initialize-SmartPrompt` — Initializes a smart fallback prompt when Starship is not available.
- `global` — Enhanced prompt function

Dependencies
------------

None explicit; see the fragment for runtime checks and optional tooling dependencies.

Notes
-----

Keep this fragment idempotent and avoid heavy probes at dot-source. Prefer provider-first checks and lazy enablers like Enable-* helpers.
