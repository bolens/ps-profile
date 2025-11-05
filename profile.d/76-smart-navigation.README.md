profile.d/76-smart-navigation.ps1
=================================

Purpose
-------

Smart directory navigation for PowerShell profile.

Usage
-----

See the fragment source: `76-smart-navigation.ps1` for examples and usage notes.

Functions
---------

- `Update-DirectoryStats` — Tracks directory navigation for smart jumping.
- `Jump-Directory` — Jumps to frequently used directories.
- `Jump-DirectoryQuick` — Quick directory jumping alias.
- `Show-FrequentDirectories` — Lists frequently used directories.
- `Add-DirectoryBookmark` — Creates a directory bookmark.
- `Get-DirectoryBookmark` — Jumps to a bookmarked directory.
- `Show-DirectoryBookmarks` — Lists all directory bookmarks.
- `Remove-DirectoryBookmark` — Removes a directory bookmark.
- `Set-LocationBack` — Goes back to the previous directory.
- `Set-LocationForward` — Goes forward in the navigation history.
- `Set-LocationTracked` — Enhanced change directory with navigation tracking.

Aliases
-------

- `j` — Quick directory jumping alias. (alias for `Jump-DirectoryQuick`)
- `cd` — Override built-in cd and Set-Location (alias for `Set-LocationTracked`)
- `c` — Enhanced change directory with navigation tracking. (alias for `Set-LocationTracked`)
- `b` — Quick navigation aliases (alias for `Set-LocationBack`)
- `f` — Goes forward in the navigation history. (alias for `Set-LocationForward`)
- `bm` — Lists all directory bookmarks. (alias for `Show-DirectoryBookmarks`)

Dependencies
------------

None explicit; see the fragment for runtime checks and optional tooling dependencies.

Notes
-----

Keep this fragment idempotent and avoid heavy probes at dot-source. Prefer provider-first checks and lazy enablers like Enable-* helpers.
