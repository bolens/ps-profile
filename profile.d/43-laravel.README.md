profile.d/43-laravel.ps1
========================

Purpose
-------

Laravel framework helpers (guarded)

Usage
-----

See the fragment source: `43-laravel.ps1` for examples and usage notes.

Functions
---------

- `artisan` — Register Laravel helpers lazily. Avoid expensive Get-Command probes at dot-source.
- `art` — Register Laravel helpers lazily. Avoid expensive Get-Command probes at dot-source.
- `laravel-new` — Register Laravel helpers lazily. Avoid expensive Get-Command probes at dot-source.

Dependencies
------------

None explicit; see the fragment for runtime checks and optional tooling dependencies.

Notes
-----

Keep this fragment idempotent and avoid heavy probes at dot-source. Prefer provider-first checks and lazy enablers like Enable-* helpers.
