profile.d/74-enhanced-history.ps1
=================================

Purpose
-------
Enhanced history search and navigation for PowerShell profile.

Usage
-----
See the fragment source: `74-enhanced-history.ps1` for examples and usage notes.

Functions
---------
- `Find-HistoryFuzzy` — >
- `fh` — >
- `Show-HistoryStats` — >
- `Remove-HistoryDuplicates` — >
- `Remove-OldHistory` — >
- `Invoke-LastCommand` — >
- `Show-RecentCommands` — >
- `r` — >
- `Search-HistoryInteractive` — >

Dependencies
------------
None explicit; see the fragment for runtime checks and optional tooling dependencies.

Notes
-----
Keep this fragment idempotent and avoid heavy probes at dot-source. Prefer provider-first checks and lazy enablers like Enable-* helpers.
