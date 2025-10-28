profile.d/46-vite.ps1
=====================

Purpose
-------
Vite build tool helpers (guarded)

Usage
-----
See the fragment source: `46-vite.ps1` for examples and usage notes.

Functions
---------
- `vite` — Vite execute - run vite with arguments
- `create-vite` — Create Vite project - scaffold new Vite project
- `vite-dev` — Vite dev server - start development server
- `vite-build` — Vite build - create production build

Dependencies
------------
None explicit; see the fragment for runtime checks and optional tooling dependencies.

Notes
-----
Keep this fragment idempotent and avoid heavy probes at dot-source. Prefer provider-first checks and lazy enablers like Enable-* helpers.

