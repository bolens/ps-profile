profile.d/17-kubectl.ps1
========================

Purpose
-------

Small kubectl shorthands and helpers

Usage
-----

See the fragment source: `17-kubectl.ps1` for examples and usage notes.

Functions
---------

- `k` — 17-kubectl.ps1
- `kn` — 17-kubectl.ps1
- `kg` — kubectl get - get Kubernetes resources
- `kd` — kubectl describe - describe Kubernetes resources
- `kctx` — kubectl context - show current context

Dependencies
------------

None explicit; see the fragment for runtime checks and optional tooling dependencies.

Notes
-----

Keep this fragment idempotent and avoid heavy probes at dot-source. Prefer provider-first checks and lazy enablers like Enable-* helpers.
