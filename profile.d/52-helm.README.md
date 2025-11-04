profile.d/52-helm.ps1
=====================

Purpose
-------
Helm Kubernetes package manager helpers (guarded)

Usage
-----
See the fragment source: `52-helm.ps1` for examples and usage notes.

Functions
---------
- `helm` — Helm execute - run helm with arguments
- `helm-install` — Helm install - install Helm charts
- `helm-upgrade` — Helm upgrade - upgrade Helm releases
- `helm-list` — Helm list - list Helm releases

Dependencies
------------
None explicit; see the fragment for runtime checks and optional tooling dependencies.

Notes
-----
Keep this fragment idempotent and avoid heavy probes at dot-source. Prefer provider-first checks and lazy enablers like Enable-* helpers.
