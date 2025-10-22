profile.d/28-aws.ps1
====================

Purpose
-------
AWS CLI helpers (guarded)

Usage
-----
See the fragment source: `28-aws.ps1` for examples and usage notes.

Functions
---------
- `aws` — AWS execute - run aws with arguments
- `aws-profile` — AWS profile switcher - set AWS profile
- `aws-region` — AWS region switcher - set AWS region

Dependencies
------------
None explicit; see the fragment for runtime checks and optional tooling dependencies.

Notes
-----
Keep this fragment idempotent and avoid heavy probes at dot-source. Prefer provider-first checks and lazy enablers like Enable-* helpers.
