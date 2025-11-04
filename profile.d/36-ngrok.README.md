profile.d/36-ngrok.ps1
======================

Purpose
-------
Ngrok tunneling helpers (guarded)

Usage
-----
See the fragment source: `36-ngrok.ps1` for examples and usage notes.

Functions
---------
- `ngrok` — Ngrok execute - run ngrok with arguments
- `ngrok-http` — Ngrok HTTP tunnel - expose local HTTP server
- `ngrok-tcp` — Ngrok TCP tunnel - expose local TCP service

Dependencies
------------
None explicit; see the fragment for runtime checks and optional tooling dependencies.

Notes
-----
Keep this fragment idempotent and avoid heavy probes at dot-source. Prefer provider-first checks and lazy enablers like Enable-* helpers.
