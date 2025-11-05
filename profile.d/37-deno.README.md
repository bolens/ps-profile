profile.d/37-deno.ps1
=====================

Purpose
-------
Deno JavaScript runtime helpers (guarded)

Usage
-----
See the fragment source: `37-deno.ps1` for examples and usage notes.

Functions
---------
- `deno` — Register Deno helpers lazily. Avoid expensive Get-Command probes at dot-source.
- `deno-run` — Register Deno helpers lazily. Avoid expensive Get-Command probes at dot-source.
- `deno-task` — Deno task - run defined tasks from deno.json

Dependencies
------------
None explicit; see the fragment for runtime checks and optional tooling dependencies.

Notes
-----
Keep this fragment idempotent and avoid heavy probes at dot-source. Prefer provider-first checks and lazy enablers like Enable-* helpers.
