profile.d/06-oh-my-posh.ps1
===========================

Purpose
-------
Idempotent initialization for oh-my-posh prompt framework.

Usage
-----
See the fragment source: `06-oh-my-posh.ps1` for examples and usage notes.

Functions
---------
- `Initialize-OhMyPosh`
- `Prompt` — ScriptBlock object to avoid simple textual recursion.

Dependencies
------------
None explicit; see the fragment for runtime checks and optional tooling dependencies.

Notes
-----
Keep this fragment idempotent and avoid heavy probes at dot-source. Prefer provider-first checks and lazy enablers like Enable-* helpers.
