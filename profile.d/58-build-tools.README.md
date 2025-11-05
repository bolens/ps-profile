profile.d/58-build-tools.ps1
============================

Purpose
-------
Build tools and dev servers helpers (guarded)

Usage
-----
See the fragment source: `58-build-tools.ps1` for examples and usage notes.

Functions
---------
- `turbo` — Register build tools and development server helpers lazily. Avoid expensive Get-Command probes at dot-source.
- `esbuild` — esbuild - extremely fast JavaScript bundler
- `rollup` — rollup - JavaScript module bundler
- `serve` — serve - static file serving and directory listing
- `http-server` — http-server - simple zero-configuration command-line http server

Dependencies
------------
None explicit; see the fragment for runtime checks and optional tooling dependencies.

Notes
-----
Keep this fragment idempotent and avoid heavy probes at dot-source. Prefer provider-first checks and lazy enablers like Enable-* helpers.
