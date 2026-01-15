# Install-BrewPackage

## Synopsis

Installs packages using Homebrew.

## Description

Installs packages using Homebrew. Supports --cask for GUI applications.

## Signature

```powershell
Install-BrewPackage
```

## Parameters

### -Packages

Package names to install.

### -Cask

Install as cask (GUI application).


## Examples

### Example 1

`powershell
Install-BrewPackage git
        Installs git.
``

### Example 2

`powershell
Install-BrewPackage -Cask visual-studio-code
        Installs Visual Studio Code as a cask.
``

## Aliases

This function has the following aliases:

- `brewadd` - Installs packages using Homebrew.
- `brewinstall` - Installs packages using Homebrew.


## Source

Defined in: ..\profile.d\homebrew.ps1
