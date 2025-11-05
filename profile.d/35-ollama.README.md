profile.d/35-ollama.ps1
=======================

Purpose
-------

Ollama AI model helpers (guarded)

Usage
-----

See the fragment source: `35-ollama.ps1` for examples and usage notes.

Functions
---------

- `ol` — Register Ollama helpers lazily. Avoid expensive Get-Command probes at dot-source.
- `ol-list` — Register Ollama helpers lazily. Avoid expensive Get-Command probes at dot-source.
- `ol-run` — Ollama run - run an AI model interactively
- `ol-pull` — Ollama pull - download an AI model

Dependencies
------------

None explicit; see the fragment for runtime checks and optional tooling dependencies.

Notes
-----

Keep this fragment idempotent and avoid heavy probes at dot-source. Prefer provider-first checks and lazy enablers like Enable-* helpers.
