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
- `reload` — Reload profile in current session
- `edit-profile` — Edit profile in code editor
- `weather` — Weather info for a location (city, zip, etc.)
- `myip` — Get public IP address
- `speedtest` — Run speedtest-cli
- `Get-History` — History helpers
- `hg` — Search history
- `pwgen` — Generate random password
- `from-epoch` — Convert Unix timestamp to DateTime
- `epoch` — Convert DateTime to Unix timestamp
- `now` — Get current date and time in standard format
- `open-explorer` — Open current directory in File Explorer
- `list-functions` — List all user-defined functions in current session
- `backup-profile` — Backup current profile to timestamped .bak file

Dependencies
------------
None explicit; see the fragment for runtime checks and optional tooling dependencies.

Notes
-----
Keep this fragment idempotent and avoid heavy probes at dot-source. Prefer provider-first checks and lazy enablers like Enable-* helpers.

