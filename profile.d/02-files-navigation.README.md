profile.d/02-files-navigation.ps1
=================================

Purpose
-------
File navigation utilities

Usage
-----
See the fragment source: `02-files-navigation.ps1` for examples and usage notes.

Functions
---------
- `Ensure-FileNavigation` — Initializes file navigation utility functions on first use.
- `global` — Up directory
- `global` — Up two directories
- `global` — Up three directories
- `Set-LocationDesktop` — Changes to the Desktop directory.
- `Set-LocationDownloads` — Changes to the Downloads directory.
- `Set-LocationDocuments` — Changes to the Documents directory.
- `~` — Go to user's Home directory

Aliases
-------
- `desktop` — Go to user's Home directory (alias for `Set-LocationDesktop`)
- `downloads` — Go to user's Downloads directory (alias for `Set-LocationDownloads`)
- `docs` — Go to user's Documents directory (alias for `Set-LocationDocuments`)

Dependencies
------------
None explicit; see the fragment for runtime checks and optional tooling dependencies.

Notes
-----
Keep this fragment idempotent and avoid heavy probes at dot-source. Prefer provider-first checks and lazy enablers like Enable-* helpers.
