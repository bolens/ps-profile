profile.d/00-bootstrap.ps1
==========================

Purpose
-------
Bootstrap helpers for profile fragments

Usage
-----
See the fragment source: `00-bootstrap.ps1` for examples and usage notes.

Functions
---------
- `Set-AgentModeFunction` — Collision-safe function creator for profile fragments
- `Set-AgentModeAlias` — Collision-safe alias creator for profile fragments
- `Test-CachedCommand` — Lightweight cached command-test used by multiple fragments to avoid repeated Get-Command calls
- `Test-HasCommand` — Small utility exported for fragments: prefer provider checks first to avoid module autoload

Dependencies
------------
None explicit; see the fragment for runtime checks and optional tooling dependencies.

Notes
-----
Keep this fragment idempotent and avoid heavy probes at dot-source. Prefer provider-first checks and lazy enablers like Enable-* helpers.

