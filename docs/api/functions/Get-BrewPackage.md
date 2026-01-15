# Get-BrewPackage

## Synopsis

Lists installed Homebrew packages.

## Description

Shows all packages currently installed via Homebrew.

## Signature

```powershell
Get-BrewPackage
```

## Parameters

### -Cask

List casks (GUI applications) instead of formulae.

### -Versions

Show installed versions for each package.


## Examples

### Example 1

`powershell
Get-BrewPackage
        Lists all installed Homebrew formulae.
``

### Example 2

`powershell
Get-BrewPackage -Cask
        Lists all installed casks.
``

### Example 3

`powershell
Get-BrewPackage -Versions
        Lists formulae with their installed versions.
``

## Aliases

This function has the following aliases:

- `brewlist` - Lists installed Homebrew packages.


## Source

Defined in: ..\profile.d\homebrew.ps1
