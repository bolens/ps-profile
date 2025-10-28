profile.d/08-system-info.ps1
============================

Purpose
-------
System information helpers

Usage
-----
See the fragment source: `08-system-info.ps1` for examples and usage notes.

Functions
---------
- `uptime` — System information helpers
- `battery`
- `sysinfo`
- `cpuinfo`
- `meminfo`

Dependencies
------------
None explicit; see the fragment for runtime checks and optional tooling dependencies.

Notes
-----
Keep this fragment idempotent and avoid heavy probes at dot-source. Prefer provider-first checks and lazy enablers like Enable-* helpers.

