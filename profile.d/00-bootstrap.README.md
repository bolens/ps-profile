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

- `Set-AgentModeFunction` — Creates collision-safe functions for profile fragments.
- `Set-AgentModeAlias` — Creates collision-safe aliases for profile fragments.
- `Test-CachedCommand` — Tests for command availability with caching.
- `Test-HasCommand` — Tests if a command is available.

Dependencies
------------

None explicit; see the fragment for runtime checks and optional tooling dependencies.

Notes
-----

Keep this fragment idempotent and avoid heavy probes at dot-source. Prefer provider-first checks and lazy enablers like Enable-* helpers.
