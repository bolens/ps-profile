profile.d/47-angular.ps1
========================

Purpose
-------

Angular CLI helpers (guarded)

Usage
-----

See the fragment source: `47-angular.ps1` for examples and usage notes.

Functions
---------

- `ng` — Register Angular helpers lazily. Avoid expensive Get-Command probes at dot-source.
- `ng-new` — Angular new project - create new Angular application
- `ng-serve` — Angular serve - start development server

Dependencies
------------

None explicit; see the fragment for runtime checks and optional tooling dependencies.

Notes
-----

Keep this fragment idempotent and avoid heavy probes at dot-source. Prefer provider-first checks and lazy enablers like Enable-* helpers.
