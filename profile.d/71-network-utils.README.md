profile.d/71-network-utils.ps1
==============================

Purpose
-------
Network utilities with error recovery and timeout handling.

Usage
-----
See the fragment source: `71-network-utils.ps1` for examples and usage notes.

Functions
---------
- `Invoke-WithRetry` — >
- `Test-NetworkConnectivity` — >
- `Invoke-HttpRequestWithRetry` — >
- `Resolve-HostWithRetry` — >

Dependencies
------------
None explicit; see the fragment for runtime checks and optional tooling dependencies.

Notes
-----
Keep this fragment idempotent and avoid heavy probes at dot-source. Prefer provider-first checks and lazy enablers like Enable-* helpers.
