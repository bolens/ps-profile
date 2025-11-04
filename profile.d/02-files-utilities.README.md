profile.d/02-files-utilities.ps1
================================

Purpose
-------
File utility functions

Usage
-----
See the fragment source: `02-files-utilities.ps1` for examples and usage notes.

Functions
---------
- `Ensure-FileUtilities` — >
- `head` — >
- `tail` — >
- `file-hash` — >
- `filesize` — >
- `hex-dump` — >

Dependencies
------------
None explicit; see the fragment for runtime checks and optional tooling dependencies.

Notes
-----
Keep this fragment idempotent and avoid heavy probes at dot-source. Prefer provider-first checks and lazy enablers like Enable-* helpers.
