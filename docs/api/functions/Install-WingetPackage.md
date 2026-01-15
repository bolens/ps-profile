# Install-WingetPackage

## Synopsis

Installs packages using winget.

## Description

Installs packages from the winget repository.

## Signature

```powershell
Install-WingetPackage
```

## Parameters

### -Packages

Package IDs or names to install.

### -Version

Specific version to install (--version).

### -Source

Source to install from (--source).


## Examples

### Example 1

`powershell
Install-WingetPackage Microsoft.VisualStudioCode
        Installs Visual Studio Code.
``

### Example 2

`powershell
Install-WingetPackage Git.Git -Version 2.40.0
        Installs a specific version of Git.
``

## Aliases

This function has the following aliases:

- `winget-add` - Installs packages using winget.
- `winget-install` - Installs packages using winget.


## Source

Defined in: ..\profile.d\winget.ps1
