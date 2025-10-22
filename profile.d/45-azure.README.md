profile.d/45-azure.ps1
======================

Purpose
-------
Azure CLI helpers (guarded)

Usage
-----
See the fragment source: `45-azure.ps1` for examples and usage notes.

Functions
---------
- `az` — Azure execute - run az with arguments
- `azd` — Azure Developer CLI - Azure development tools
- `az-login` — Azure login - authenticate with Azure CLI
- `azd-up` — Azure Developer CLI up - provision and deploy

Dependencies
------------
None explicit; see the fragment for runtime checks and optional tooling dependencies.

Notes
-----
Keep this fragment idempotent and avoid heavy probes at dot-source. Prefer provider-first checks and lazy enablers like Enable-* helpers.
