profile.d/11-ansible.ps1
========================

Purpose
-------
Ansible wrappers that execute via WSL to ensure Linux toolchain compatibility

Usage
-----
See the fragment source: `11-ansible.ps1` for examples and usage notes.

Functions
---------
- `ansible` — Ansible wrappers that execute via WSL to ensure Linux toolchain compatibility
- `ansible-playbook`
- `ansible-galaxy`
- `ansible-vault`
- `ansible-doc`
- `ansible-inventory`

Dependencies
------------
None explicit; see the fragment for runtime checks and optional tooling dependencies.

Notes
-----
Keep this fragment idempotent and avoid heavy probes at dot-source. Prefer provider-first checks and lazy enablers like Enable-* helpers.
