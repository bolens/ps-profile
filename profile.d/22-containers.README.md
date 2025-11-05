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
- `Get-ContainerEngineInfo` — Gets information about available container engines and compose tools.
- `Start-ContainerCompose` — Starts container services using compose (Docker-first).
- `Stop-ContainerCompose` — Stops container services using compose (Docker-first).
- `Get-ContainerComposeLogs` — Shows container logs using compose (Docker-first).
- `Clear-ContainerSystem` — Prunes unused container system resources (Docker-first).
- `Start-ContainerComposePodman` — Starts container services using compose (Podman-first).
- `Stop-ContainerComposePodman` — Stops container services using compose (Podman-first).
- `Get-ContainerComposeLogsPodman` — Shows container logs using compose (Podman-first).
- `Clear-ContainerSystemPodman` — Prunes unused container system resources (Podman-first).

Aliases
-------
- `dcu` — Starts container services using compose (Docker-first). (alias for `Start-ContainerCompose`)
- `dcd` — Stops container services using compose (Docker-first). (alias for `Stop-ContainerCompose`)
- `dcl` — Shows container logs using compose (Docker-first). (alias for `Get-ContainerComposeLogs`)
- `dprune` — Prunes unused container system resources (Docker-first). (alias for `Clear-ContainerSystem`)
- `pcu` — Starts container services using compose (Podman-first). (alias for `Start-ContainerComposePodman`)
- `pcd` — Stops container services using compose (Podman-first). (alias for `Stop-ContainerComposePodman`)
- `pcl` — Shows container logs using compose (Podman-first). (alias for `Get-ContainerComposeLogsPodman`)
- `pprune` — Prunes unused container system resources (Podman-first). (alias for `Clear-ContainerSystemPodman`)

Dependencies
------------
None explicit; see the fragment for runtime checks and optional tooling dependencies.

Notes
-----
Keep this fragment idempotent and avoid heavy probes at dot-source. Prefer provider-first checks and lazy enablers like Enable-* helpers.
