profile.d/62-navi.ps1
=====================

Purpose
-------

Interactive cheatsheet tool

Usage
-----

See the fragment source: `62-navi.ps1` for examples and usage notes.

Functions
---------

- `Invoke-NaviSearch` — Searches navi cheatsheets interactively.
- `Invoke-NaviBest` — Finds the best matching command from navi cheatsheets.
- `Invoke-NaviPrint` — Prints commands from navi cheatsheets without executing them.

Aliases
-------

- `cheats` — Main navi command (alias for `navi`)
- `navis` — Searches navi cheatsheets interactively. (alias for `Invoke-NaviSearch`)
- `navib` — Finds the best matching command from navi cheatsheets. (alias for `Invoke-NaviBest`)
- `navip` — Prints commands from navi cheatsheets without executing them. (alias for `Invoke-NaviPrint`)

Dependencies
------------

None explicit; see the fragment for runtime checks and optional tooling dependencies.

Notes
-----

Keep this fragment idempotent and avoid heavy probes at dot-source. Prefer provider-first checks and lazy enablers like Enable-* helpers.
