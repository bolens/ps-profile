profile.d/68-pixi.ps1
=====================

Purpose
-------

Package management with pixi

Usage
-----

See the fragment source: `68-pixi.ps1` for examples and usage notes.

Functions
---------

- `Invoke-PixiInstall` — Installs packages using pixi.
- `Invoke-PixiRun` — Runs commands in the pixi environment.
- `Invoke-PixiShell` — Activates the pixi shell environment.

Aliases
-------

- `pxadd` — Installs packages using pixi. (alias for `Invoke-PixiInstall`)
- `pxrun` — Runs commands in the pixi environment. (alias for `Invoke-PixiRun`)
- `pxshell` — Activates the pixi shell environment. (alias for `Invoke-PixiShell`)

Dependencies
------------

None explicit; see the fragment for runtime checks and optional tooling dependencies.

Notes
-----

Keep this fragment idempotent and avoid heavy probes at dot-source. Prefer provider-first checks and lazy enablers like Enable-* helpers.
