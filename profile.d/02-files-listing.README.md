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

- `Ensure-FileListing` — Initializes file listing utility functions on first use.
- `Get-ChildItemDetailed` — Lists directory contents with details.
- `Get-ChildItemAll` — Lists all directory contents including hidden files.
- `Get-ChildItemVisible` — Lists directory contents excluding hidden files.
- `Get-DirectoryTree` — Displays directory structure as a tree.
- `Show-FileContent` — Displays file contents with syntax highlighting.

Aliases
-------

- `ll` — Listing helpers (prefer eza when available) (alias for `Get-ChildItemDetailed`)
- `la` — Lists all directory contents including hidden files. (alias for `Get-ChildItemAll`)
- `lx` — Lists directory contents excluding hidden files. (alias for `Get-ChildItemVisible`)
- `tree` — Displays directory structure as a tree. (alias for `Get-DirectoryTree`)
- `bat-cat` — bat wrapper (alias for `Show-FileContent`)

Dependencies
------------

None explicit; see the fragment for runtime checks and optional tooling dependencies.

Notes
-----

Keep this fragment idempotent and avoid heavy probes at dot-source. Prefer provider-first checks and lazy enablers like Enable-* helpers.
