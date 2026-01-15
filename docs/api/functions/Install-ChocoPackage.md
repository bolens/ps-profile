# Install-ChocoPackage

## Synopsis

Installs packages using Chocolatey.

## Description

Installs packages using Chocolatey. Supports --version and --source flags.

## Signature

```powershell
Install-ChocoPackage
```

## Parameters

### -Packages

Package names to install.

### -Version

Specific version to install.

### -Source

Source to install from.

### -Yes

Auto-confirm all prompts.


## Examples

### Example 1

`powershell
Install-ChocoPackage git
        Installs git.
``

### Example 2

`powershell
Install-ChocoPackage git -Version 2.40.0
        Installs specific version of git.
``

## Aliases

This function has the following aliases:

- `choadd` - Installs packages using Chocolatey.
- `choinstall` - Installs packages using Chocolatey.


## Source

Defined in: ..\profile.d\chocolatey.ps1
