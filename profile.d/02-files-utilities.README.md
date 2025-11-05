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

- `Ensure-FileUtilities` — Initializes file utility functions on first use.
- `Get-FileHead` — Shows the first N lines of a file.
- `Get-FileTail` — Shows the last N lines of a file.
- `Get-FileHashValue` — Calculates file hash using specified algorithm.
- `Get-FileSize` — Shows human-readable file size.
- `Get-HexDump` — Shows hex dump of a file.

Aliases
-------

- `head` — Shows the first N lines of a file. (alias for `Get-FileHead`)
- `tail` — Shows the last N lines of a file. (alias for `Get-FileTail`)
- `file-hash` — File hash (alias for `Get-FileHashValue`)
- `filesize` — File size (alias for `Get-FileSize`)
- `hex-dump` — Hex dump (alias for `Get-HexDump`)

Dependencies
------------

None explicit; see the fragment for runtime checks and optional tooling dependencies.

Notes
-----

Keep this fragment idempotent and avoid heavy probes at dot-source. Prefer provider-first checks and lazy enablers like Enable-* helpers.
