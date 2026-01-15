# Export-PipPackages

## Synopsis

Exports installed pip packages to a requirements.txt file.

## Description

Creates a requirements.txt file containing all installed pip packages with versions. This file can be used to restore packages on another system or after a reinstall.

## Signature

```powershell
Export-PipPackages
```

## Parameters

### -Path

Path to save the export file. Defaults to "requirements.txt" in current directory.

### -User

Export only user-installed packages (--user flag).


## Examples

### Example 1

`powershell
Export-PipPackages
        Exports packages to requirements.txt in current directory.
``

### Example 2

`powershell
Export-PipPackages -Path "C:\backup\pip-requirements.txt"
        Exports packages to a specific file.
``

### Example 3

`powershell
Export-PipPackages -User
        Exports only user-installed packages.
``

## Aliases

This function has the following aliases:

- `pipbackup` - Exports installed pip packages to a requirements.txt file.
- `pipexport` - Exports installed pip packages to a requirements.txt file.


## Source

Defined in: ..\profile.d\pip.ps1
