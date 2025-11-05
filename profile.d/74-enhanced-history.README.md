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

- `Find-HistoryFuzzy` — Performs fuzzy search on command history.
- `Find-HistoryQuick` — Quick search in command history.
- `Show-HistoryStats` — Shows statistics about command history usage.
- `Remove-HistoryDuplicates` — Removes duplicate commands from history.
- `Remove-OldHistory` — Removes old commands from history.
- `Invoke-LastCommand` — Shows the last command matching a pattern.
- `Show-RecentCommands` — Shows recent commands with quick selection.
- `r` — Executes a command from recent history by number or pattern.
- `Search-HistoryInteractive` — Interactive history search with preview.

Aliases
-------

- `fh` — Quick search in command history. (alias for `Find-HistoryQuick`)

Dependencies
------------

None explicit; see the fragment for runtime checks and optional tooling dependencies.

Notes
-----

Keep this fragment idempotent and avoid heavy probes at dot-source. Prefer provider-first checks and lazy enablers like Enable-* helpers.
