# Remove-BrewPackage

## Synopsis

Removes packages using Homebrew.

## Description

Removes packages using Homebrew. Supports --cask for GUI applications.

## Signature

```powershell
Remove-BrewPackage
```

## Parameters

### -Packages

Package names to remove.

### -Cask

Remove cask (GUI application).


## Examples

### Example 1

`powershell
Remove-BrewPackage git
        Removes git.
``

### Example 2

`powershell
Remove-BrewPackage -Cask visual-studio-code
        Removes Visual Studio Code cask.
``

## Aliases

This function has the following aliases:

- `brewremove` - Removes packages using Homebrew.
- `brewuninstall` - Removes packages using Homebrew.


## Source

Defined in: ..\profile.d\homebrew.ps1
