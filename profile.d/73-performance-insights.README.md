profile.d/73-performance-insights.ps1
=====================================

Purpose
-------
Command timing and performance insights for PowerShell profile.

Usage
-----
See the fragment source: `73-performance-insights.ps1` for examples and usage notes.

Functions
---------
- `Start-CommandTimer` — Tracks command execution performance and provides insights.
- `Stop-CommandTimer` — Stops command timing and records the duration.
- `Show-PerformanceInsights` — Shows performance insights for command execution.
- `Test-PerformanceHealth` — Performs a quick performance check of the current session.
- `Clear-PerformanceData` — Clears all collected performance data.
- `global` — Enhanced prompt with timing

Dependencies
------------
None explicit; see the fragment for runtime checks and optional tooling dependencies.

Notes
-----
Keep this fragment idempotent and avoid heavy probes at dot-source. Prefer provider-first checks and lazy enablers like Enable-* helpers.
