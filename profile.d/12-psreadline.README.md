profile.d/12-psreadline.ps1
===========================

Purpose
-------

Configures PSReadLine options (history, key bindings) in an idempotent

Usage
-----

See the fragment source: `12-psreadline.ps1` for examples and usage notes.

Functions
---------

- `global` — Register a lazy enabler that imports and configures PSReadLine on demand.

Dependencies
------------

None explicit; see the fragment for runtime checks and optional tooling dependencies.

Notes
-----

Keep this fragment idempotent and avoid heavy probes at dot-source. Prefer provider-first checks and lazy enablers like Enable-* helpers.
