profile.d/35-rustup.ps1
=======================

Purpose
-------
Rustup toolchain helpers (guarded)

Usage
-----
See the fragment source: `35-rustup.ps1` for examples and usage notes.

Functions
---------
- `rustup` — Rustup execute - run rustup with arguments
- `rustup-update` — Rustup update - update Rust toolchain
- `rustup-install` — Rustup install - install Rust toolchains

Dependencies
------------
None explicit; see the fragment for runtime checks and optional tooling dependencies.

Notes
-----
Keep this fragment idempotent and avoid heavy probes at dot-source. Prefer provider-first checks and lazy enablers like Enable-* helpers.
