# Get-AnsibleInventory

## Synopsis

Runs Ansible inventory commands via WSL with UTF-8 locale.

## Description

Executes ansible-inventory commands through WSL bash shell with proper UTF-8 locale settings for Linux toolchain compatibility.

## Signature

```powershell
Get-AnsibleInventory
```

## Parameters

### -Arguments

Arguments to pass to ansible-inventory.


## Examples

### Example 1

`powershell
Get-AnsibleInventory --list
``

### Example 2

`powershell
Get-AnsibleInventory --host webserver
``

## Aliases

This function has the following aliases:

- `ansible-inventory` - Runs Ansible inventory commands via WSL with UTF-8 locale.


## Source

Defined in: ..\profile.d\13-ansible.ps1
