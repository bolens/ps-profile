profile.d/42-php.ps1
====================

Purpose
-------
PHP development helpers (guarded)

Usage
-----
See the fragment source: `42-php.ps1` for examples and usage notes.

Functions
---------
- `php` — Register PHP helpers lazily. Avoid expensive Get-Command probes at dot-source.
- `php-server` — Register PHP helpers lazily. Avoid expensive Get-Command probes at dot-source.
- `composer` — Composer - PHP dependency manager

Dependencies
------------
None explicit; see the fragment for runtime checks and optional tooling dependencies.

Notes
-----
Keep this fragment idempotent and avoid heavy probes at dot-source. Prefer provider-first checks and lazy enablers like Enable-* helpers.
