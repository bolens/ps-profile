# Import-NpmGlobalPackages

## Synopsis

Restores globally installed npm packages from a backup file.

## Description

Installs all packages listed in a package.json file as global packages. This is useful for restoring packages after a system reinstall or on a new machine.

## Signature

```powershell
Import-NpmGlobalPackages
```

## Parameters

### -Path

Path to the package.json file to import. Defaults to "npm-global-packages.json" in current directory.


## Examples

### Example 1

`powershell
Import-NpmGlobalPackages
        Restores global packages from npm-global-packages.json in current directory.
``

### Example 2

`powershell
Import-NpmGlobalPackages -Path "C:\backup\npm-global.json"
        Restores global packages from a specific file.
``

## Aliases

This function has the following aliases:

- `npmimport` - Restores globally installed npm packages from a backup file.
- `npmrestore` - Restores globally installed npm packages from a backup file.


## Source

Defined in: ..\profile.d\npm.ps1
