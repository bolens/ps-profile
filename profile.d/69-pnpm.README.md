# profile.d/69-pnpm.ps1
====================

Purpose
-------
Provides aliases for pnpm, a fast and disk-efficient package manager.

Usage
-----
See the fragment source: `69-pnpm.ps1` for examples and usage notes.

Functions
---------
- `Invoke-PnpmInstall` — Installs packages using pnpm
- `Invoke-PnpmDevInstall` — Installs development packages using pnpm
- `Invoke-PnpmRun` — Runs npm scripts using pnpm

Aliases
-------
- `npm` — pnpm (npm replacement)
- `yarn` — pnpm (yarn replacement)
- `pnadd` — Invoke-PnpmInstall
- `pndev` — Invoke-PnpmDevInstall
- `pnrun` — Invoke-PnpmRun

Dependencies
------------
- pnpm (install with: scoop install pnpm)

Notes
-----
PNPM is faster and more efficient than npm, with better disk usage through hard linking.
