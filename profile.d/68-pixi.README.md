# profile.d/68-pixi.ps1
====================

Purpose
-------
Provides aliases for pixi, a package management tool.

Usage
-----
See the fragment source: `68-pixi.ps1` for examples and usage notes.

Functions
---------
- `Invoke-PixiInstall` — Installs packages using pixi
- `Invoke-PixiRun` — Runs commands in the pixi environment
- `Invoke-PixiShell` — Activates the pixi shell environment

Aliases
-------
- `pxadd` — Invoke-PixiInstall
- `pxrun` — Invoke-PixiRun
- `pxshell` — Invoke-PixiShell

Dependencies
------------
- pixi (install with: scoop install pixi)

Notes
-----
Pixi manages packages and environments for multiple languages.
