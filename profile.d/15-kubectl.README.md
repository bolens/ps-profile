profile.d/15-kubectl.ps1
========================

Purpose
-------
Small kubectl shorthands and helpers

Usage
-----
See the fragment source: `15-kubectl.ps1` for examples and usage notes.

Functions
---------
- `k` — kubectl alias - run kubectl with arguments
- `kn` — kubectl context switcher - switch Kubernetes context
- `kg` — kubectl get - get Kubernetes resources
- `kd` — kubectl describe - describe Kubernetes resources
- `kctx` — kubectl context - show current context

Dependencies
------------
None explicit; see the fragment for runtime checks and optional tooling dependencies.

Notes
-----
Keep this fragment idempotent and avoid heavy probes at dot-source. Prefer provider-first checks and lazy enablers like Enable-* helpers.
