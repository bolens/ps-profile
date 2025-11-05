profile.d/51-gcloud.ps1
=======================

Purpose
-------
Google Cloud CLI helpers (guarded)

Usage
-----
See the fragment source: `51-gcloud.ps1` for examples and usage notes.

Functions
---------
- `gcloud` — Register Google Cloud CLI helpers lazily. Avoid expensive Get-Command probes at dot-source.
- `gcloud-auth` — Register Google Cloud CLI helpers lazily. Avoid expensive Get-Command probes at dot-source.
- `gcloud-config` — Google Cloud config - manage configuration
- `gcloud-projects` — Google Cloud projects - manage GCP projects

Dependencies
------------
None explicit; see the fragment for runtime checks and optional tooling dependencies.

Notes
-----
Keep this fragment idempotent and avoid heavy probes at dot-source. Prefer provider-first checks and lazy enablers like Enable-* helpers.
