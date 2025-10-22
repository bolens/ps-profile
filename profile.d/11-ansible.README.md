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
- `ansible` — Ansible command wrappers for WSL with UTF-8 locale
- `ansible-playbook` — Ansible-playbook command wrapper for WSL with UTF-8 locale
- `ansible-galaxy` — Ansible-galaxy command wrapper for WSL with UTF-8 locale
- `ansible-vault` — Ansible-vault command wrapper for WSL with UTF-8 locale
- `ansible-doc` — Ansible-doc command wrapper for WSL with UTF-8 locale
- `ansible-inventory` — Ansible-inventory command wrapper for WSL with UTF-8 locale

Dependencies
------------
None explicit; see the fragment for runtime checks and optional tooling dependencies.

Notes
-----
Keep this fragment idempotent and avoid heavy probes at dot-source. Prefer provider-first checks and lazy enablers like Enable-* helpers.
