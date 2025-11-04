profile.d/05-utilities.ps1
==========================

Purpose
-------
Utility functions migrated from utilities.ps1

Usage
-----
See the fragment source: `05-utilities.ps1` for examples and usage notes.

Functions
---------
- `reload` — >
- `edit-profile` — >
- `weather` — >
- `myip` — >
- `speedtest` — >
- `Get-History` — >
- `hg` — >
- `pwgen` — >
- `url-encode` — >
- `url-decode` — >
- `from-epoch` — >
- `to-epoch` — >
- `epoch` — >
- `now` — >
- `open-explorer` — >
- `list-functions` — >
- `backup-profile` — >
- `Get-EnvVar` — >
- `Set-EnvVar` — >
- `Publish-EnvVar` — >
- `Remove-Path` — >
- `Add-Path` — >

Dependencies
------------
None explicit; see the fragment for runtime checks and optional tooling dependencies.

Notes
-----
Keep this fragment idempotent and avoid heavy probes at dot-source. Prefer provider-first checks and lazy enablers like Enable-* helpers.
