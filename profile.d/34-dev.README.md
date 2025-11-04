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
- `d` — d: docker wrapper
- `dc` — dc: docker-compose wrapper
- `dps` — dps: docker ps wrapper
- `di` — di: docker images wrapper
- `drm` — drm: docker rm wrapper
- `drmi` — drmi: docker rmi wrapper
- `dexec` — dexec: docker exec -it wrapper
- `dlogs` — dlogs: docker logs wrapper
- `pd` — pd: podman wrapper
- `pps` — pps: podman ps wrapper
- `pi` — pi: podman images wrapper
- `prmi` — prmi: podman rmi wrapper
- `pdexec` — pdexec: podman exec -it wrapper
- `pdlogs` — pdlogs: podman logs wrapper
- `n` — n: npm wrapper
- `ni` — ni: npm install wrapper
- `nr` — nr: npm run wrapper
- `ns` — ns: npm start wrapper
- `nt` — nt: npm test wrapper
- `np` — np: npm publish wrapper
- `nb` — nb: npm run build wrapper
- `nrd` — nrd: npm run dev wrapper
- `py` — py: python wrapper
- `venv` — venv: python virtual environment wrapper
- `activate` — activate: activate virtual environment
- `req` — req: generate requirements.txt
- `pipi` — pipi: pip install wrapper
- `pipu` — pipu: pip install --upgrade wrapper
- `cr` — cr: cargo run wrapper
- `cb` — cb: cargo build wrapper
- `ct` — ct: cargo test wrapper
- `cc` — cc: cargo check wrapper
- `cu` — cu: cargo update wrapper
- `ca` — ca: cargo add wrapper
- `cw` — cw: cargo watch -x run wrapper
- `cd` — cd: cargo doc --open wrapper
- `cl` — cl: cargo clippy wrapper
- `cf` — cf: cargo fmt wrapper
- `ci` — ci: cargo install wrapper

Dependencies
------------
None explicit; see the fragment for runtime checks and optional tooling dependencies.

Notes
-----
Keep this fragment idempotent and avoid heavy probes at dot-source. Prefer provider-first checks and lazy enablers like Enable-* helpers.
