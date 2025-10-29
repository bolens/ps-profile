# profile.d/62-navi.ps1
====================

Purpose
-------
Provides aliases and functions for navi, an interactive cheatsheet tool.

Usage
-----
See the fragment source: `62-navi.ps1` for examples and usage notes.

Functions
---------
- `Invoke-NaviSearch` — Search navi cheatsheets interactively
- `Invoke-NaviBest` — Get best matching command from cheatsheets
- `Invoke-NaviPrint` — Print command from cheatsheets without executing

Aliases
-------
- `cheats` — navi (main command)
- `navis` — Invoke-NaviSearch
- `navib` — Invoke-NaviBest
- `navip` — Invoke-NaviPrint

Dependencies
------------
- navi (install with: scoop install navi)

Notes
-----
Navi helps you find commands interactively. Use cheats to browse available commands.
