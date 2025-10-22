profile.d/20-containers.ps1
===========================

Purpose
-------
Container helpers consolidated (docker / podman / compose)

Usage
-----
See the fragment source: `20-containers.ps1` for examples and usage notes.

Functions
---------
- `Get-ContainerEngineInfo` — implementation before calling.
- `dcu` — docker-compose / docker compose up
- `dcd` — docker-compose down
- `dcl` — docker-compose logs -f
- `dprune` — prune system for whichever engine
- `pcu` — Podman-first compose helpers (separate functions for convenience)
- `pcd`
- `pcl`
- `pprune`

Dependencies
------------
None explicit; see the fragment for runtime checks and optional tooling dependencies.

Notes
-----
Keep this fragment idempotent and avoid heavy probes at dot-source. Prefer provider-first checks and lazy enablers like Enable-* helpers.
