profile.d/70-profile-updates.ps1
================================

Purpose
-------
Profile update checker with changelog display. Runs periodically to check for

Usage
-----
See the fragment source: `70-profile-updates.ps1` for examples and usage notes.

Functions
---------
- `Test-ProfileUpdates` — Checks for profile updates and displays changelog.

Dependencies
------------
None explicit; see the fragment for runtime checks and optional tooling dependencies.

Notes
-----
Keep this fragment idempotent and avoid heavy probes at dot-source. Prefer provider-first checks and lazy enablers like Enable-* helpers.
