# Export-NpmGlobalPackages

## Synopsis

Exports globally installed npm packages to a backup file.

## Description

Creates a package.json file containing all globally installed npm packages. This file can be used to restore packages on another system or after a reinstall.

## Signature

```powershell
Export-NpmGlobalPackages
```

## Parameters

### -Path

Path to save the export file. Defaults to "npm-global-packages.json" in current directory.


## Examples

### Example 1

`powershell
Export-NpmGlobalPackages
        Exports global packages to npm-global-packages.json in current directory.
``

### Example 2

`powershell
Export-NpmGlobalPackages -Path "C:\backup\npm-global.json"
        Exports global packages to a specific file.
``

## Aliases

This function has the following aliases:

- `npmbackup` - Exports globally installed npm packages to a backup file.
- `npmexport` - Exports globally installed npm packages to a backup file.


## Source

Defined in: ..\profile.d\npm.ps1
