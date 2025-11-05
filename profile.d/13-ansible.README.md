profile.d/13-ansible.ps1
========================

Purpose
-------

Ansible wrappers that execute via WSL to ensure Linux toolchain compatibility

Usage
-----

See the fragment source: `13-ansible.ps1` for examples and usage notes.

Functions
---------

- `Invoke-Ansible` — Runs Ansible commands via WSL with UTF-8 locale.
- `Invoke-AnsiblePlaybook` — Runs Ansible playbook commands via WSL with UTF-8 locale.
- `Invoke-AnsibleGalaxy` — Runs Ansible Galaxy commands via WSL with UTF-8 locale.
- `Invoke-AnsibleVault` — Runs Ansible Vault commands via WSL with UTF-8 locale.
- `Get-AnsibleDoc` — Runs Ansible documentation commands via WSL with UTF-8 locale.
- `Get-AnsibleInventory` — Runs Ansible inventory commands via WSL with UTF-8 locale.

Aliases
-------

- `ansible` — Runs Ansible commands via WSL with UTF-8 locale. (alias for `Invoke-Ansible`)
- `ansible-playbook` — Runs Ansible playbook commands via WSL with UTF-8 locale. (alias for `Invoke-AnsiblePlaybook`)
- `ansible-galaxy` — Runs Ansible Galaxy commands via WSL with UTF-8 locale. (alias for `Invoke-AnsibleGalaxy`)
- `ansible-vault` — Runs Ansible Vault commands via WSL with UTF-8 locale. (alias for `Invoke-AnsibleVault`)
- `ansible-doc` — Runs Ansible documentation commands via WSL with UTF-8 locale. (alias for `Get-AnsibleDoc`)
- `ansible-inventory` — Runs Ansible inventory commands via WSL with UTF-8 locale. (alias for `Get-AnsibleInventory`)

Dependencies
------------

None explicit; see the fragment for runtime checks and optional tooling dependencies.

Notes
-----

Keep this fragment idempotent and avoid heavy probes at dot-source. Prefer provider-first checks and lazy enablers like Enable-* helpers.
