profile.d/40-tailscale.ps1
==========================

Purpose
-------
Tailscale VPN helpers (guarded)

Usage
-----
See the fragment source: `40-tailscale.ps1` for examples and usage notes.

Functions
---------
- `tailscale` — Register Tailscale helpers lazily. Avoid expensive Get-Command probes at dot-source.
- `ts-up` — Register Tailscale helpers lazily. Avoid expensive Get-Command probes at dot-source.
- `ts-down` — Tailscale down - disconnect from Tailscale network
- `ts-status` — Tailscale status - show connection status

Dependencies
------------
None explicit; see the fragment for runtime checks and optional tooling dependencies.

Notes
-----
Keep this fragment idempotent and avoid heavy probes at dot-source. Prefer provider-first checks and lazy enablers like Enable-* helpers.
