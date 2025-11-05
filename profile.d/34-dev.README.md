profile.d/34-dev.ps1
====================

Purpose
-------

Development shortcuts (docker, podman, k8s, node, python, cargo)

Usage
-----

See the fragment source: `34-dev.ps1` for examples and usage notes.

Functions
---------

- `d` — 34-dev.ps1
- `dc` — 34-dev.ps1
- `dps` — 34-dev.ps1
- `di` — 34-dev.ps1
- `drm` — 34-dev.ps1
- `drmi` — 34-dev.ps1
- `dexec` — 34-dev.ps1
- `dlogs` — 34-dev.ps1
- `pd` — 34-dev.ps1
- `pps` — 34-dev.ps1
- `pi` — 34-dev.ps1
- `prmi` — 34-dev.ps1
- `pdexec` — Docker shortcuts
- `pdlogs` — Docker shortcuts
- `n` — dps: docker ps wrapper
- `ni` — di: docker images wrapper
- `nr` — drm: docker rm wrapper
- `ns` — drmi: docker rmi wrapper
- `nt` — dexec: docker exec -it wrapper
- `np` — dlogs: docker logs wrapper
- `nb` — Podman shortcuts
- `nrd` — Podman shortcuts
- `py` — pi: podman images wrapper
- `venv` — prmi: podman rmi wrapper
- `activate` — pdexec: podman exec -it wrapper
- `req` — pdlogs: podman logs wrapper
- `pipi` — Node.js shortcuts
- `pipu` — Node.js shortcuts
- `cr` — nr: npm run wrapper
- `cb` — ns: npm start wrapper
- `ct` — nt: npm test wrapper
- `cc` — np: npm publish wrapper
- `cu` — nb: npm run build wrapper
- `ca` — nrd: npm run dev wrapper
- `cw` — Python shortcuts
- `cd` — Python shortcuts
- `cl` — venv: python virtual environment wrapper
- `cf` — activate: activate virtual environment
- `ci` — req: generate requirements.txt

Dependencies
------------

None explicit; see the fragment for runtime checks and optional tooling dependencies.

Notes
-----

Keep this fragment idempotent and avoid heavy probes at dot-source. Prefer provider-first checks and lazy enablers like Enable-* helpers.
