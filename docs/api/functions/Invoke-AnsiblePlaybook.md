# Invoke-AnsiblePlaybook

## Synopsis

Runs Ansible playbook commands via WSL with UTF-8 locale.

## Description

Executes ansible-playbook commands through WSL bash shell with proper UTF-8 locale settings for Linux toolchain compatibility.

## Signature

```powershell
Invoke-AnsiblePlaybook
```

## Parameters

### -Arguments

Arguments to pass to ansible-playbook.


## Examples

### Example 1

`powershell
Invoke-AnsiblePlaybook playbook.yml
``

### Example 2

`powershell
Invoke-AnsiblePlaybook playbook.yml --check
``

## Aliases

This function has the following aliases:

- `ansible-playbook` - Runs Ansible playbook commands via WSL with UTF-8 locale.


## Source

Defined in: ..\profile.d\ansible.ps1
