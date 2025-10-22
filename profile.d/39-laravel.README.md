profile.d/39-laravel.ps1
========================

Purpose
-------
Laravel framework helpers (guarded)

Usage
-----
See the fragment source: `39-laravel.ps1` for examples and usage notes.

Functions
---------
- `artisan` — Laravel artisan command - run artisan commands
- `art` — Laravel artisan alias - run artisan commands
- `laravel-new` — Laravel new project - create new Laravel application

Dependencies
------------
None explicit; see the fragment for runtime checks and optional tooling dependencies.

Notes
-----
Keep this fragment idempotent and avoid heavy probes at dot-source. Prefer provider-first checks and lazy enablers like Enable-* helpers.
