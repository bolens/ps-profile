profile.d/56-database.ps1
=========================

Purpose
-------
Database tools helpers (guarded)

Usage
-----
See the fragment source: `56-database.ps1` for examples and usage notes.

Functions
---------
- `psql` — Register database tools helpers lazily. Avoid expensive Get-Command probes at dot-source.
- `mysql` — Register database tools helpers lazily. Avoid expensive Get-Command probes at dot-source.
- `mongosh` — Register database tools helpers lazily. Avoid expensive Get-Command probes at dot-source.
- `redis-cli` — Register database tools helpers lazily. Avoid expensive Get-Command probes at dot-source.
- `sqlite3` — SQLite CLI - command-line interface for SQLite databases

Dependencies
------------
None explicit; see the fragment for runtime checks and optional tooling dependencies.

Notes
-----
Keep this fragment idempotent and avoid heavy probes at dot-source. Prefer provider-first checks and lazy enablers like Enable-* helpers.
