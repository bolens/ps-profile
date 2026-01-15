# Get-AnsibleDoc

## Synopsis

Runs Ansible documentation commands via WSL with UTF-8 locale.

## Description

Executes ansible-doc commands through WSL bash shell with proper UTF-8 locale settings for Linux toolchain compatibility.

## Signature

```powershell
Get-AnsibleDoc
```

## Parameters

### -Arguments

Arguments to pass to ansible-doc.


## Examples

### Example 1

`powershell
Get-AnsibleDoc ping
``

### Example 2

`powershell
Get-AnsibleDoc -l
``

## Aliases

This function has the following aliases:

- `ansible-doc` - Runs Ansible documentation commands via WSL with UTF-8 locale.


## Source

Defined in: ..\profile.d\ansible.ps1
