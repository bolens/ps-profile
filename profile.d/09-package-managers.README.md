profile.d/09-package-managers.ps1
=================================

Purpose
-------
Package manager helper shorthands (Scoop, uv, etc.)

Usage
-----
See the fragment source: `09-package-managers.ps1` for examples and usage notes.

Functions
---------
- `sinstall` — Scoop install
- `ss` — Scoop search
- `su` — Scoop update
- `suu` — Scoop update all
- `sr` — Scoop uninstall
- `slist` — Scoop list
- `sh` — Scoop info
- `scleanup` — Scoop cleanup
- `uvi` — UV install
- `uvr` — UV run
- `uvx` — UV tool run
- `uva` — UV add
- `uvs` — UV sync
- `pni` — PNPM install
- `pna` — PNPM add
- `pnd` — PNPM add -D
- `pnr` — PNPM run
- `pns` — PNPM start, build, test, dev
- `pnb` — PNPM build
- `pnt` — PNPM test
- `pndev` — PNPM dev

Dependencies
------------
None explicit; see the fragment for runtime checks and optional tooling dependencies.

Notes
-----
Keep this fragment idempotent and avoid heavy probes at dot-source. Prefer provider-first checks and lazy enablers like Enable-* helpers.

