# Import-ChocoPackages

## Synopsis

Restores Chocolatey packages from a backup file.

## Description

Installs all packages listed in a packages.config file. This is useful for restoring packages after a system reinstall or on a new machine.

## Signature

```powershell
Import-ChocoPackages
```

## Parameters

### -Path

Path to the packages.config file to import. Defaults to "packages.config" in current directory.

### -Yes

Auto-confirm all prompts.


## Examples

### Example 1

`powershell
Import-ChocoPackages
        Restores packages from packages.config in current directory.
``

### Example 2

`powershell
Import-ChocoPackages -Path "C:\backup\choco-packages.config"
        Restores packages from a specific file.
``

## Aliases

This function has the following aliases:

- `choimport` - Restores Chocolatey packages from a backup file.
- `chorestore` - Restores Chocolatey packages from a backup file.


## Source

Defined in: ..\profile.d\chocolatey.ps1
