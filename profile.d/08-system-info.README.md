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

- `Get-SystemUptime` — Shows system uptime.
- `Get-BatteryInfo` — Shows battery information.
- `Get-SystemInfo` — Shows system information.
- `Get-CpuInfo` — Shows CPU information.
- `Get-MemoryInfo` — Shows memory information.

Aliases
-------

- `uptime` — Shows system uptime. (alias for `Get-SystemUptime`)
- `battery` — Shows battery information. (alias for `Get-BatteryInfo`)
- `sysinfo` — Shows system information. (alias for `Get-SystemInfo`)
- `cpuinfo` — Shows CPU information. (alias for `Get-CpuInfo`)
- `meminfo` — Shows memory information. (alias for `Get-MemoryInfo`)

Dependencies
------------

None explicit; see the fragment for runtime checks and optional tooling dependencies.

Notes
-----

Keep this fragment idempotent and avoid heavy probes at dot-source. Prefer provider-first checks and lazy enablers like Enable-* helpers.
