profile.d/45-nextjs.ps1
=======================

Purpose
-------
Next.js development helpers (guarded)

Usage
-----
See the fragment source: `45-nextjs.ps1` for examples and usage notes.

Functions
---------
- `next-dev` — Next.js dev server - start development server
- `next-build` — Next.js build - create production build
- `next-start` — Next.js start - start production server
- `create-next-app` — Create Next.js app - bootstrap a new Next.js application

Dependencies
------------
None explicit; see the fragment for runtime checks and optional tooling dependencies.

Notes
-----
Keep this fragment idempotent and avoid heavy probes at dot-source. Prefer provider-first checks and lazy enablers like Enable-* helpers.
