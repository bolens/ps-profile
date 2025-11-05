profile.d/59-diagnostics.ps1
============================

Purpose
-------

Small diagnostics helpers that are only verbose when `PS_PROFILE_DEBUG` is

Usage
-----

See the fragment source: `59-diagnostics.ps1` for examples and usage notes.

Functions
---------

- `Show-ProfileDiagnostic` — Shows profile diagnostic information.
- `Show-ProfileStartupTime` — Shows profile startup time information.
- `Test-ProfileHealth` — Performs basic health checks for critical dependencies.
- `Show-CommandUsageStats` — Shows command usage statistics for optimization insights.

Dependencies
------------

None explicit; see the fragment for runtime checks and optional tooling dependencies.

Notes
-----

Keep this fragment idempotent and avoid heavy probes at dot-source. Prefer provider-first checks and lazy enablers like Enable-* helpers.
