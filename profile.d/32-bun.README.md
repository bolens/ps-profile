profile.d/32-bun.ps1
====================

Purpose
-------
Bun JavaScript runtime helpers (guarded)

Usage
-----
See the fragment source: `32-bun.ps1` for examples and usage notes.

Functions
---------
- `bunx` — Bun execute - run bunx with arguments
- `bun-run` — Bun run script - execute npm scripts with bun
- `bun-add` — Bun add package - install npm packages with bun

Dependencies
------------
None explicit; see the fragment for runtime checks and optional tooling dependencies.

Notes
-----
Keep this fragment idempotent and avoid heavy probes at dot-source. Prefer provider-first checks and lazy enablers like Enable-* helpers.
