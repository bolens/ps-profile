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
- `php` — PHP execute - run php with arguments
- `php-server` — PHP built-in server - start development server
- `composer` — Composer - PHP dependency manager

Dependencies
------------
None explicit; see the fragment for runtime checks and optional tooling dependencies.

Notes
-----
Keep this fragment idempotent and avoid heavy probes at dot-source. Prefer provider-first checks and lazy enablers like Enable-* helpers.
