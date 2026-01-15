# Export-BrewPackages

## Synopsis

Exports installed Homebrew packages to a Brewfile.

## Description

Creates a Brewfile containing all installed Homebrew formulae, casks, and taps. This file can be used to restore packages on another system or after a reinstall.

## Signature

```powershell
Export-BrewPackages
```

## Parameters

### -Path

Path to save the Brewfile. Defaults to "Brewfile" in current directory.

### -Describe

Include descriptions for each package in the Brewfile.

### -Force

Overwrite existing Brewfile if it exists.


## Examples

### Example 1

`powershell
Export-BrewPackages
        Exports packages to Brewfile in current directory.
``

### Example 2

`powershell
Export-BrewPackages -Path "~/backup/Brewfile"
        Exports packages to a specific file.
``

### Example 3

`powershell
Export-BrewPackages -Describe
        Exports packages with descriptions included.
``

## Aliases

This function has the following aliases:

- `brewbackup` - Exports installed Homebrew packages to a Brewfile.
- `brewexport` - Exports installed Homebrew packages to a Brewfile.


## Source

Defined in: ..\profile.d\homebrew.ps1
