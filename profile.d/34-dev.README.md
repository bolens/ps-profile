profile.d/34-dev.ps1
====================

Purpose
-------
Development shortcuts (docker, podman, k8s, node, python, cargo)

Usage
-----
See the fragment source: `34-dev.ps1` for examples and usage notes.

Functions
---------
- `d` — Docker shortcuts
- `dps` — dc: docker-compose wrapper — register a stub if not present
- `di`
- `drm`
- `drmi`
- `dexec`
- `dlogs`
- `pd` — Podman shortcuts
- `pps`
- `pi`
- `New-Item` — Node.js shortcuts
- `nr`
- `ns`
- `nt`
- `nb`
- `nrd`
- `py` — Python shortcuts
- `venv`
- `activate`
- `req`
- `pipi`
- `pipu`
- `cr` — Cargo/Rust shortcuts
- `ct` — in this file was removed to avoid duplicate command registrations.
- `cc`
- `cu`
- `ca`
- `cw`
- `dc` — dc: docker-compose wrapper — register a stub if not present

Dependencies
------------
None explicit; see the fragment for runtime checks and optional tooling dependencies.

Notes
-----
Keep this fragment idempotent and avoid heavy probes at dot-source. Prefer provider-first checks and lazy enablers like Enable-* helpers.

