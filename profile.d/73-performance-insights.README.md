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
- `Start-CommandTimer` — >
- `Stop-CommandTimer` — >
- `Show-PerformanceInsights` — >
- `Test-PerformanceHealth` — >
- `Clear-PerformanceData` — >
- `global` — Enhanced prompt with timing

Dependencies
------------
None explicit; see the fragment for runtime checks and optional tooling dependencies.

Notes
-----
Keep this fragment idempotent and avoid heavy probes at dot-source. Prefer provider-first checks and lazy enablers like Enable-* helpers.
