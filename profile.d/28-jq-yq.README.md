profile.d/28-jq-yq.ps1
======================

Purpose
-------
jq and yq helpers (guarded)

Usage
-----
See the fragment source: `28-jq-yq.ps1` for examples and usage notes.

Functions
---------
- `jq2json` — Register jq/yq helpers lazily. Avoid expensive Get-Command probes at dot-source.
- `yq2json` — yq to JSON converter - convert YAML to JSON

Dependencies
------------
None explicit; see the fragment for runtime checks and optional tooling dependencies.

Notes
-----
Keep this fragment idempotent and avoid heavy probes at dot-source. Prefer provider-first checks and lazy enablers like Enable-* helpers.
