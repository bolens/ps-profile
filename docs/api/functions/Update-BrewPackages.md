# Update-BrewPackages

## Synopsis

Updates Homebrew packages.

## Description

Updates specified packages or all packages if no arguments provided.

## Signature

```powershell
Update-BrewPackages
```

## Parameters

### -Packages

Package names to update (optional, updates all if omitted).


## Examples

### Example 1

`powershell
Update-BrewPackages
        Updates all packages.
``

### Example 2

`powershell
Update-BrewPackages git
        Updates git package.
``

## Aliases

This function has the following aliases:

- `brewupdate` - Updates Homebrew packages.
- `brewupgrade` - Updates Homebrew packages.


## Source

Defined in: ..\profile.d\homebrew.ps1
