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
- `Ensure-FileNavigation` — >
- `global` — Up directory
- `global` — Up two directories
- `global` — Up three directories
- `desktop` — >
- `downloads` — >
- `docs` — >
- `~` — Go to user's Home directory

Dependencies
------------
None explicit; see the fragment for runtime checks and optional tooling dependencies.

Notes
-----
Keep this fragment idempotent and avoid heavy probes at dot-source. Prefer provider-first checks and lazy enablers like Enable-* helpers.
