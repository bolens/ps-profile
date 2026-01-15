# Invoke-AnsibleVault

## Synopsis

Runs Ansible Vault commands via WSL with UTF-8 locale.

## Description

Executes ansible-vault commands through WSL bash shell with proper UTF-8 locale settings for Linux toolchain compatibility.

## Signature

```powershell
Invoke-AnsibleVault
```

## Parameters

### -Arguments

Arguments to pass to ansible-vault.


## Examples

### Example 1

`powershell
Invoke-AnsibleVault encrypt secrets.yml
``

### Example 2

`powershell
Invoke-AnsibleVault decrypt secrets.yml
``

## Aliases

This function has the following aliases:

- `ansible-vault` - Runs Ansible Vault commands via WSL with UTF-8 locale.


## Source

Defined in: ..\profile.d\ansible.ps1
