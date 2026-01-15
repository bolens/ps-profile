# Import-BrewPackages

## Synopsis

Restores Homebrew packages from a Brewfile.

## Description

Installs all packages listed in a Brewfile. This is useful for restoring packages after a system reinstall or on a new machine.

## Signature

```powershell
Import-BrewPackages
```

## Parameters

### -Path

Path to the Brewfile to import. Defaults to "Brewfile" in current directory.

### -NoLock

Don't update the Brewfile.lock.json file.

### -NoUpgrade

Don't run brew upgrade for outdated packages.


## Examples

### Example 1

`powershell
Import-BrewPackages
        Restores packages from Brewfile in current directory.
``

### Example 2

`powershell
Import-BrewPackages -Path "~/backup/Brewfile"
        Restores packages from a specific file.
``

## Aliases

This function has the following aliases:

- `brewimport` - Restores Homebrew packages from a Brewfile.
- `brewrestore` - Restores Homebrew packages from a Brewfile.


## Source

Defined in: ..\profile.d\homebrew.ps1
