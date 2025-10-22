profile.d/31-ollama.ps1
=======================

Purpose
-------
Ollama AI model helpers (guarded)

Usage
-----
See the fragment source: `31-ollama.ps1` for examples and usage notes.

Functions
---------
- `ol` — Ollama alias - run ollama with arguments
- `ol-list` — Ollama list - list available models
- `ol-run` — Ollama run - run an AI model interactively
- `ol-pull` — Ollama pull - download an AI model

Dependencies
------------
None explicit; see the fragment for runtime checks and optional tooling dependencies.

Notes
-----
Keep this fragment idempotent and avoid heavy probes at dot-source. Prefer provider-first checks and lazy enablers like Enable-* helpers.
