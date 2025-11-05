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
- `Write-ProfileError` — Logs errors with enhanced context and formatting.
- `Invoke-ProfileErrorHandler` — Enhanced global error handler with recovery suggestions.
- `Invoke-SafeFragmentLoad` — Loads profile fragments with enhanced error handling and retry logic.

Dependencies
------------
None explicit; see the fragment for runtime checks and optional tooling dependencies.

Notes
-----
Keep this fragment idempotent and avoid heavy probes at dot-source. Prefer provider-first checks and lazy enablers like Enable-* helpers.
