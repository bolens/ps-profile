# Get-BrewPackageInfo

## Synopsis

Shows information about Homebrew packages.

## Description

Displays detailed information about specified packages, including version, description, dependencies, and installation status.

## Signature

```powershell
Get-BrewPackageInfo
```

## Parameters

### -Packages

Package names to get information for.

### -Cask

Get information for casks (GUI applications) instead of formulae.


## Examples

### Example 1

`powershell
Get-BrewPackageInfo git
        Shows detailed information about the git package.
``

### Example 2

`powershell
Get-BrewPackageInfo visual-studio-code -Cask
        Shows information for the Visual Studio Code cask.
``

## Aliases

This function has the following aliases:

- `brewinfo` - Shows information about Homebrew packages.


## Source

Defined in: ..\profile.d\homebrew.ps1
