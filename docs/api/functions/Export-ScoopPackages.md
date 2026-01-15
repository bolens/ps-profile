# Export-ScoopPackages

## Synopsis

Exports installed Scoop packages to a backup file.

## Description

Creates a JSON file containing all installed Scoop packages. This file can be used to restore packages on another system or after a reinstall.

## Signature

```powershell
Export-ScoopPackages
```

## Parameters

### -Path

Path to save the export file. Defaults to "scoopfile.json" in current directory.


## Examples

### Example 1

`powershell
Export-ScoopPackages
        Exports packages to scoopfile.json in current directory.
``

### Example 2

`powershell
Export-ScoopPackages -Path "C:\backup\scoop-packages.json"
        Exports packages to a specific file.
``

## Aliases

This function has the following aliases:

- `scoopbackup` - Exports installed Scoop packages to a backup file.
- `scoopexport` - Exports installed Scoop packages to a backup file.


## Source

Defined in: ..\profile.d\scoop.ps1
