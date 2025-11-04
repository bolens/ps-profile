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
- `Update-DirectoryStats` — >
- `Jump-Directory` — >
- `j` — >
- `Show-FrequentDirectories` — >
- `Add-DirectoryBookmark` — >
- `Get-DirectoryBookmark` — >
- `Show-DirectoryBookmarks` — >
- `Remove-DirectoryBookmark` — >
- `Set-LocationBack` — >
- `Set-LocationForward` — >
- `Set-LocationTracked` — >

Dependencies
------------
None explicit; see the fragment for runtime checks and optional tooling dependencies.

Notes
-----
Keep this fragment idempotent and avoid heavy probes at dot-source. Prefer provider-first checks and lazy enablers like Enable-* helpers.
