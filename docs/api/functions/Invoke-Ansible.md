# Invoke-Ansible

## Synopsis

Runs Ansible commands via WSL with UTF-8 locale.

## Description

Executes ansible commands through WSL bash shell with proper UTF-8 locale settings for Linux toolchain compatibility.

## Signature

```powershell
Invoke-Ansible
```

## Parameters

### -Arguments

Arguments to pass to ansible.


## Examples

### Example 1

`powershell
Invoke-Ansible --version
``

### Example 2

`powershell
Invoke-Ansible all -m ping
``

## Aliases

This function has the following aliases:

- `ansible` - Runs Ansible commands via WSL with UTF-8 locale.


## Source

Defined in: ..\profile.d\13-ansible.ps1
