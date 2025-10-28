profile.d/03-agent-mode.ps1
===========================

Purpose
-------
Thin compatibility shim for legacy "agent-mode" helpers.

Usage
-----
See the fragment source: `03-agent-mode.ps1` for examples and usage notes.

Functions
---------
- `am-list` — Provide a safe, backwards-compatible alias for listing functions
- `am-doc` — Compatibility: open the legacy agent-mode README if present

Dependencies
------------
None explicit; see the fragment for runtime checks and optional tooling dependencies.

Notes
-----
Keep this fragment idempotent and avoid heavy probes at dot-source. Prefer provider-first checks and lazy enablers like Enable-* helpers.

