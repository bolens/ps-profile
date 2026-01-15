# Import-ScoopPackages

## Synopsis

Restores Scoop packages from a backup file.

## Description

Installs all packages listed in a scoopfile.json file. This is useful for restoring packages after a system reinstall or on a new machine.

## Signature

```powershell
Import-ScoopPackages
```

## Parameters

### -Path

Path to the scoopfile.json file to import. Defaults to "scoopfile.json" in current directory.


## Examples

### Example 1

`powershell
Import-ScoopPackages
        Restores packages from scoopfile.json in current directory.
``

### Example 2

`powershell
Import-ScoopPackages -Path "C:\backup\scoop-packages.json"
        Restores packages from a specific file.
``

## Aliases

This function has the following aliases:

- `scoopimport` - Restores Scoop packages from a backup file.
- `scooprestore` - Restores Scoop packages from a backup file.


## Source

Defined in: ..\profile.d\scoop.ps1
