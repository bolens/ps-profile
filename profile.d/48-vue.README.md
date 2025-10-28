profile.d/48-vue.ps1
====================

Purpose
-------
Vue.js development helpers (guarded)

Usage
-----
See the fragment source: `48-vue.ps1` for examples and usage notes.

Functions
---------
- `vue` — Vue execute - run vue with arguments
- `vue-create` — Vue create project - create new Vue.js project
- `vue-serve` — Vue serve - start development server

Dependencies
------------
None explicit; see the fragment for runtime checks and optional tooling dependencies.

Notes
-----
Keep this fragment idempotent and avoid heavy probes at dot-source. Prefer provider-first checks and lazy enablers like Enable-* helpers.

