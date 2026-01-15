# Find-BrewPackage

## Synopsis

Searches for Homebrew packages.

## Description

Searches for available packages in Homebrew repositories.

## Signature

```powershell
Find-BrewPackage
```

## Parameters

### -Query

Search query string.

### -Cask

Search for casks (GUI applications) instead of formulae.


## Examples

### Example 1

`powershell
Find-BrewPackage git
        Searches for packages containing "git".
``

### Example 2

`powershell
Find-BrewPackage visual-studio-code -Cask
        Searches for casks containing "visual-studio-code".
``

## Aliases

This function has the following aliases:

- `brewfind` - Searches for Homebrew packages.
- `brewsearch` - Searches for Homebrew packages.


## Source

Defined in: ..\profile.d\homebrew.ps1
