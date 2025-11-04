profile.d/22-containers.ps1
===========================

Purpose
-------
Container helpers consolidated (docker / podman / compose)

Usage
-----
See the fragment source: `22-containers.ps1` for examples and usage notes.

Functions
---------
- `Get-ContainerEngineInfo` — >
- `dcu` — >
- `dcd` — >
- `dcl` — >
- `dprune` — >
- `pcu` — >
- `pcd` — >
- `pcl` — >
- `pprune` — >

Dependencies
------------
None explicit; see the fragment for runtime checks and optional tooling dependencies.

Notes
-----
Keep this fragment idempotent and avoid heavy probes at dot-source. Prefer provider-first checks and lazy enablers like Enable-* helpers.
