profile.d/24-minio.ps1
======================

Purpose
-------
MinIO client helpers (mc) — guarded

Usage
-----
See the fragment source: `24-minio.ps1` for examples and usage notes.

Functions
---------
- `mc-ls` — MinIO list - list files in MinIO
- `mc-cp` — MinIO copy - copy files to/from MinIO

Dependencies
------------
None explicit; see the fragment for runtime checks and optional tooling dependencies.

Notes
-----
Keep this fragment idempotent and avoid heavy probes at dot-source. Prefer provider-first checks and lazy enablers like Enable-* helpers.
