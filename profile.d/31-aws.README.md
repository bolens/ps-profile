profile.d/31-aws.ps1
====================

Purpose
-------

AWS CLI helpers (guarded)

Usage
-----

See the fragment source: `31-aws.ps1` for examples and usage notes.

Functions
---------

- `aws` — Register AWS CLI helpers lazily. Avoid expensive Get-Command probes at dot-source.
- `aws-profile` — Register AWS CLI helpers lazily. Avoid expensive Get-Command probes at dot-source.
- `aws-region` — AWS region switcher - set AWS region

Dependencies
------------

None explicit; see the fragment for runtime checks and optional tooling dependencies.

Notes
-----

Keep this fragment idempotent and avoid heavy probes at dot-source. Prefer provider-first checks and lazy enablers like Enable-* helpers.
