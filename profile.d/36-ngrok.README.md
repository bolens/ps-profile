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

- `ngrok` — Register Ngrok helpers lazily. Avoid expensive Get-Command probes at dot-source.
- `ngrok-http` — Register Ngrok helpers lazily. Avoid expensive Get-Command probes at dot-source.
- `ngrok-tcp` — Ngrok TCP tunnel - expose local TCP service

Dependencies
------------

None explicit; see the fragment for runtime checks and optional tooling dependencies.

Notes
-----

Keep this fragment idempotent and avoid heavy probes at dot-source. Prefer provider-first checks and lazy enablers like Enable-* helpers.
