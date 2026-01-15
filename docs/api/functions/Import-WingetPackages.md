# Import-WingetPackages

## Synopsis

Restores winget packages from a backup file.

## Description

Installs all packages listed in a JSON export file. This is useful for restoring packages after a system reinstall or on a new machine.

## Signature

```powershell
Import-WingetPackages
```

## Parameters

### -Path

Path to the JSON file to import. Defaults to "winget-packages.json" in current directory.

### -IgnoreUnavailable

Skip packages that are not available in the repository.

### -IgnoreVersions

Install latest versions instead of the versions specified in the export file.


## Examples

### Example 1

`powershell
Import-WingetPackages
        Restores packages from winget-packages.json in current directory.
``

### Example 2

`powershell
Import-WingetPackages -Path "C:\backup\winget-backup.json"
        Restores packages from a specific file.
``

### Example 3

`powershell
Import-WingetPackages -IgnoreUnavailable
        Restores packages, skipping any that are no longer available.
``

## Aliases

This function has the following aliases:

- `winget-import` - Restores winget packages from a backup file.
- `winget-restore` - Restores winget packages from a backup file.


## Source

Defined in: ..\profile.d\winget.ps1
