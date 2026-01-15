# Export-ChocoPackages

## Synopsis

Exports installed Chocolatey packages to a backup file.

## Description

Creates a packages.config file containing all installed Chocolatey packages. This file can be used to restore packages on another system or after a reinstall.

## Signature

```powershell
Export-ChocoPackages
```

## Parameters

### -Path

Path to save the export file. Defaults to "packages.config" in current directory.

### -IncludeVersions

Include version numbers in the export file.

### -ExcludeDependencies

Exclude dependencies from the export (only top-level packages).


## Examples

### Example 1

`powershell
Export-ChocoPackages
        Exports packages to packages.config in current directory.
``

### Example 2

`powershell
Export-ChocoPackages -Path "C:\backup\choco-packages.config"
        Exports packages to a specific file.
``

### Example 3

`powershell
Export-ChocoPackages -IncludeVersions
        Exports packages with version numbers included.
``

## Aliases

This function has the following aliases:

- `chobackup` - Exports installed Chocolatey packages to a backup file.
- `choexport` - Exports installed Chocolatey packages to a backup file.


## Source

Defined in: ..\profile.d\chocolatey.ps1
