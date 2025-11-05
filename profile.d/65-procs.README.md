profile.d/65-procs.ps1
======================

Purpose
-------
Modern process viewer with procs

Usage
-----
See the fragment source: `65-procs.ps1` for examples and usage notes.

Aliases
-------
- `ps` — Main procs command (alias for `procs`)
- `psgrep` — alias for `procs`

Dependencies
------------
None explicit; see the fragment for runtime checks and optional tooling dependencies.

Notes
-----
Keep this fragment idempotent and avoid heavy probes at dot-source. Prefer provider-first checks and lazy enablers like Enable-* helpers.
