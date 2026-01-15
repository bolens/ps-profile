# Export-WingetPackages

## Synopsis

Exports installed winget packages to a backup file.

## Description

Creates a JSON file containing all installed winget packages. This file can be used to restore packages on another system or after a reinstall.

## Signature

```powershell
Export-WingetPackages
```

## Parameters

### -Path

Path to save the export file. Defaults to "winget-packages.json" in current directory.

### -Source

Export packages from a specific source only.


## Examples

### Example 1

`powershell
Export-WingetPackages
        Exports packages to winget-packages.json in current directory.
``

### Example 2

`powershell
Export-WingetPackages -Path "C:\backup\winget-backup.json"
        Exports packages to a specific file.
``

## Aliases

This function has the following aliases:

- `winget-backup` - Exports installed winget packages to a backup file.
- `winget-export` - Exports installed winget packages to a backup file.


## Source

Defined in: ..\profile.d\winget.ps1
