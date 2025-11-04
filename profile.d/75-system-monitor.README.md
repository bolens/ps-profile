profile.d/75-system-monitor.ps1
===============================

Purpose
-------
System monitoring dashboard for PowerShell profile.

Usage
-----
See the fragment source: `75-system-monitor.ps1` for examples and usage notes.

Functions
---------
- `Show-SystemDashboard` — >
- `Show-SystemStatus` — >
- `Show-CPUInfo` — >
- `Show-MemoryInfo` — >
- `Show-DiskInfo` — >
- `Show-NetworkInfo` — >

Dependencies
------------
None explicit; see the fragment for runtime checks and optional tooling dependencies.

Notes
-----
Keep this fragment idempotent and avoid heavy probes at dot-source. Prefer provider-first checks and lazy enablers like Enable-* helpers.
