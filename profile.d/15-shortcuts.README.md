profile.d/15-shortcuts.ps1
==========================

Purpose
-------
Small interactive shortcuts (editor, quick navigation, misc)

Usage
-----
See the fragment source: `15-shortcuts.ps1` for examples and usage notes.

Functions
---------
- `Open-VSCode` — Opens current directory in VS Code.
- `Open-Editor` — Opens file in editor quickly.
- `Get-ProjectRoot` — Changes to project root directory.

Aliases
-------
- `vsc` — Opens current directory in VS Code. (alias for `Open-VSCode`)
- `e` — Opens file in editor quickly. (alias for `Open-Editor`)
- `project-root` — Changes to project root directory. (alias for `Get-ProjectRoot`)

Dependencies
------------
None explicit; see the fragment for runtime checks and optional tooling dependencies.

Notes
-----
Keep this fragment idempotent and avoid heavy probes at dot-source. Prefer provider-first checks and lazy enablers like Enable-* helpers.
