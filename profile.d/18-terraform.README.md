profile.d/18-terraform.ps1
==========================

Purpose
-------
Terraform helpers (guarded)

Usage
-----
See the fragment source: `18-terraform.ps1` for examples and usage notes.

Functions
---------
- `tf` — Register terraform helpers lazily. Avoid expensive Get-Command probes at dot-source.
- `tfi` — Register terraform helpers lazily. Avoid expensive Get-Command probes at dot-source.
- `tfp` — Terraform plan - show execution plan
- `tfa` — Terraform apply - apply changes
- `tfd` — Terraform destroy - destroy infrastructure

Dependencies
------------
None explicit; see the fragment for runtime checks and optional tooling dependencies.

Notes
-----
Keep this fragment idempotent and avoid heavy probes at dot-source. Prefer provider-first checks and lazy enablers like Enable-* helpers.
