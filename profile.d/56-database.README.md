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
- `psql` — PostgreSQL client - connect to PostgreSQL databases
- `mysql` — MySQL client - connect to MySQL databases
- `mongosh` — MongoDB shell - interact with MongoDB databases
- `redis-cli` — Redis CLI - command-line interface for Redis
- `sqlite3` — SQLite CLI - command-line interface for SQLite databases

Dependencies
------------
None explicit; see the fragment for runtime checks and optional tooling dependencies.

Notes
-----
Keep this fragment idempotent and avoid heavy probes at dot-source. Prefer provider-first checks and lazy enablers like Enable-* helpers.

