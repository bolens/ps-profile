# Invoke-AnsibleGalaxy

## Synopsis

Runs Ansible Galaxy commands via WSL with UTF-8 locale.

## Description

Executes ansible-galaxy commands through WSL bash shell with proper UTF-8 locale settings for Linux toolchain compatibility.

## Signature

```powershell
Invoke-AnsibleGalaxy
```

## Parameters

### -Arguments

Arguments to pass to ansible-galaxy.


## Examples

### Example 1

`powershell
Invoke-AnsibleGalaxy install geerlingguy.docker
``

### Example 2

`powershell
Invoke-AnsibleGalaxy list
``

## Aliases

This function has the following aliases:

- `ansible-galaxy` - Runs Ansible Galaxy commands via WSL with UTF-8 locale.


## Source

Defined in: ..\profile.d\ansible.ps1
