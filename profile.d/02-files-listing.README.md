profile.d/02-files-listing.ps1
==============================

Purpose
-------
File listing utilities

Usage
-----
See the fragment source: `02-files-listing.ps1` for examples and usage notes.

Functions
---------
- `Ensure-FileListing` — >
- `ll` — >
- `la` — >
- `lx` — >
- `tree` — >
- `bat-cat` — >

Dependencies
------------
None explicit; see the fragment for runtime checks and optional tooling dependencies.

Notes
-----
Keep this fragment idempotent and avoid heavy probes at dot-source. Prefer provider-first checks and lazy enablers like Enable-* helpers.
