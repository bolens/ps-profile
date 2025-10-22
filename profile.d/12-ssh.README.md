profile.d/12-ssh.ps1
====================

Purpose
-------
SSH agent and key helpers

Usage
-----
See the fragment source: `12-ssh.ps1` for examples and usage notes.

Dependencies
------------
None explicit; see the fragment for runtime checks and optional tooling dependencies.

Notes
-----
Keep this fragment idempotent and avoid heavy probes at dot-source. Prefer provider-first checks and lazy enablers like Enable-* helpers.
