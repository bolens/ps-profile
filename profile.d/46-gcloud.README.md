profile.d/46-gcloud.ps1
=======================

Purpose
-------
Google Cloud CLI helpers (guarded)

Usage
-----
See the fragment source: `46-gcloud.ps1` for examples and usage notes.

Functions
---------
- `gcloud` — Google Cloud execute - run gcloud with arguments
- `gcloud-auth` — Google Cloud auth - manage authentication
- `gcloud-config` — Google Cloud config - manage configuration
- `gcloud-projects` — Google Cloud projects - manage GCP projects

Dependencies
------------
None explicit; see the fragment for runtime checks and optional tooling dependencies.

Notes
-----
Keep this fragment idempotent and avoid heavy probes at dot-source. Prefer provider-first checks and lazy enablers like Enable-* helpers.
