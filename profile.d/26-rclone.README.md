profile.d/26-rclone.ps1
=======================

Purpose
-------
rclone convenience helpers (guarded)

Usage
-----
See the fragment source: `26-rclone.ps1` for examples and usage notes.

Functions
---------
- `rcopy` — rclone copy - copy files to/from remote
- `rls` — rclone list - list remote files

Dependencies
------------
None explicit; see the fragment for runtime checks and optional tooling dependencies.

Notes
-----
Keep this fragment idempotent and avoid heavy probes at dot-source. Prefer provider-first checks and lazy enablers like Enable-* helpers.

