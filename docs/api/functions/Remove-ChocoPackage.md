# Remove-ChocoPackage

## Synopsis

Removes packages using Chocolatey.

## Description

Removes packages using Chocolatey. Supports --version and --remove-dependencies flags.

## Signature

```powershell
Remove-ChocoPackage
```

## Parameters

### -Packages

Package names to remove.

### -Version

Specific version to remove.

### -RemoveDependencies

Remove dependencies as well.

### -Yes

Auto-confirm all prompts.


## Examples

### Example 1

`powershell
Remove-ChocoPackage git
        Removes git.
``

### Example 2

`powershell
Remove-ChocoPackage git -RemoveDependencies
        Removes git and its dependencies.
``

## Aliases

This function has the following aliases:

- `choremove` - Removes packages using Chocolatey.
- `chouninstall` - Removes packages using Chocolatey.


## Source

Defined in: ..\profile.d\chocolatey.ps1
