profile.d/72-error-handling.ps1
===============================

Purpose
-------
Enhanced error handling and recovery mechanisms for the PowerShell profile.

Usage
-----
See the fragment source: `72-error-handling.ps1` for examples and usage notes.

Functions
---------
- `Write-ProfileError` — >
- `Invoke-ProfileErrorHandler` — >
- `Invoke-SafeFragmentLoad` — >

Dependencies
------------
None explicit; see the fragment for runtime checks and optional tooling dependencies.

Notes
-----
Keep this fragment idempotent and avoid heavy probes at dot-source. Prefer provider-first checks and lazy enablers like Enable-* helpers.
