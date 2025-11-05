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
- `Show-SystemDashboard` — Shows a comprehensive system status dashboard.
- `Show-SystemStatus` — Shows a compact system status overview.
- `Show-CPUInfo` — Shows detailed CPU information and usage.
- `Show-MemoryInfo` — Shows detailed memory usage information.
- `Show-DiskInfo` — Shows detailed disk usage information.
- `Show-NetworkInfo` — Shows detailed network information.

Aliases
-------
- `sysinfo` — Quick aliases (alias for `Show-SystemDashboard`)
- `sysstat` — Shows a compact system status overview. (alias for `Show-SystemStatus`)
- `cpuinfo` — Shows detailed CPU information and usage. (alias for `Show-CPUInfo`)
- `meminfo` — Shows detailed memory usage information. (alias for `Show-MemoryInfo`)
- `diskinfo` — Shows detailed disk usage information. (alias for `Show-DiskInfo`)
- `netinfo` — Shows detailed network information. (alias for `Show-NetworkInfo`)

Dependencies
------------
None explicit; see the fragment for runtime checks and optional tooling dependencies.

Notes
-----
Keep this fragment idempotent and avoid heavy probes at dot-source. Prefer provider-first checks and lazy enablers like Enable-* helpers.
