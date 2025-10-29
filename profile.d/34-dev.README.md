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
- `d` — Docker wrapper
- `dc` — Docker-compose wrapper
- `dps` — Docker ps wrapper
- `di` — Docker images wrapper
- `drm` — Docker rm wrapper
- `drmi` — Docker rmi wrapper
- `dexec` — Docker exec -it wrapper
- `dlogs` — Docker logs wrapper
- `pd` — Podman wrapper
- `pps` — Podman ps wrapper
- `pi` — Podman images wrapper
- `prmi` — Podman rmi wrapper
- `pdexec` — Podman exec -it wrapper
- `pdlogs` — Podman logs wrapper
- `n` — NPM wrapper
- `ni` — NPM install wrapper
- `nr` — NPM run wrapper
- `ns` — NPM start wrapper
- `nt` — NPM test wrapper
- `np` — NPM publish wrapper
- `nb` — NPM run build wrapper
- `nrd` — NPM run dev wrapper
- `py` — Python wrapper
- `venv` — Python virtual environment wrapper
- `activate` — Activate virtual environment
- `req` — Generate requirements.txt
- `pipi` — Pip install wrapper
- `pipu` — Pip install --upgrade wrapper
- `cr` — Cargo run wrapper
- `cb` — Cargo build wrapper
- `ct` — Cargo test wrapper
- `cc` — Cargo check wrapper
- `cu` — Cargo update wrapper
- `ca` — Cargo add wrapper
- `cw` — Cargo watch -x run wrapper
- `cd` — Cargo doc --open wrapper
- `cl` — Cargo clippy wrapper
- `cf` — Cargo fmt wrapper
- `ci` — Cargo install wrapper

Dependencies
------------
None explicit; see the fragment for runtime checks and optional tooling dependencies.

Notes
-----
Keep this fragment idempotent and avoid heavy probes at dot-source. Prefer provider-first checks and lazy enablers like Enable-* helpers.

