profile.d/39-rustup.ps1
=======================

Purpose
-------
Rustup toolchain helpers (guarded)

Usage
-----
See the fragment source: `39-rustup.ps1` for examples and usage notes.

Functions
---------
- `rustup` — Register Rustup helpers lazily. Avoid expensive Get-Command probes at dot-source.
- `rustup-update` — Register Rustup helpers lazily. Avoid expensive Get-Command probes at dot-source.
- `rustup-install` — Rustup install - install Rust toolchains

Dependencies
------------
None explicit; see the fragment for runtime checks and optional tooling dependencies.

Notes
-----
Keep this fragment idempotent and avoid heavy probes at dot-source. Prefer provider-first checks and lazy enablers like Enable-* helpers.
