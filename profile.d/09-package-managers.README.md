profile.d/09-package-managers.ps1
=================================

Purpose
-------
Package manager helper shorthands (Scoop, uv, pnpm, etc.)

Usage
-----
See the fragment source: `09-package-managers.ps1` for examples and usage notes.

Functions
---------
- `sinstall` — >
- `ss` — >
- `su` — >
- `suu` — >
- `sr` — >
- `slist` — >
- `sh` — >
- `scleanup` — >
- `uvi` — >
- `uvr` — >
- `uvx` — >
- `uva` — >
- `uvs` — >
- `pni` — >
- `pna` — >
- `pnd` — >
- `pnr` — >
- `pns` — >
- `pnb` — >
- `pnt` — >
- `pndev` — >

Dependencies
------------
None explicit; see the fragment for runtime checks and optional tooling dependencies.

Notes
-----
Keep this fragment idempotent and avoid heavy probes at dot-source. Prefer provider-first checks and lazy enablers like Enable-* helpers.
