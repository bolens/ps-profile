profile.d/69-pnpm.ps1
=====================

Purpose
-------
Fast package manager with pnpm

Usage
-----
See the fragment source: `69-pnpm.ps1` for examples and usage notes.

Functions
---------
- `Invoke-PnpmInstall` — Installs packages using pnpm.
- `Invoke-PnpmDevInstall` — Installs development packages using pnpm.
- `Invoke-PnpmRun` — Runs npm scripts using pnpm.

Aliases
-------
- `npm` — PNPM as npm replacement (alias for `pnpm`)
- `yarn` — alias for `pnpm`
- `pnadd` — Installs packages using pnpm. (alias for `Invoke-PnpmInstall`)
- `pndev` — Installs development packages using pnpm. (alias for `Invoke-PnpmDevInstall`)
- `pnrun` — Runs npm scripts using pnpm. (alias for `Invoke-PnpmRun`)

Dependencies
------------
None explicit; see the fragment for runtime checks and optional tooling dependencies.

Notes
-----
Keep this fragment idempotent and avoid heavy probes at dot-source. Prefer provider-first checks and lazy enablers like Enable-* helpers.
