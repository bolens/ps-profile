profile.d/49-nuxt.ps1
=====================

Purpose
-------
Nuxt.js development helpers (guarded)

Usage
-----
See the fragment source: `49-nuxt.ps1` for examples and usage notes.

Functions
---------
- `nuxi` — Nuxt execute - run nuxi with arguments
- `nuxt-dev` — Nuxt dev server - start development server
- `nuxt-build` — Nuxt build - create production build
- `create-nuxt-app` — Create Nuxt app - scaffold new Nuxt.js project

Dependencies
------------
None explicit; see the fragment for runtime checks and optional tooling dependencies.

Notes
-----
Keep this fragment idempotent and avoid heavy probes at dot-source. Prefer provider-first checks and lazy enablers like Enable-* helpers.

