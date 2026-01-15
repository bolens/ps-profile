# Remove-CondaPackage

## Synopsis

Removes packages using conda.

## Description

Removes packages. Supports environment specification with -n/--name.

## Signature

```powershell
Remove-CondaPackage
```

## Parameters

### -Packages

Package names to remove.

### -Environment

Environment name to remove from (-n/--name).


## Examples

### Example 1

`powershell
Remove-CondaPackage numpy
        Removes numpy from the current environment.
``

### Example 2

`powershell
Remove-CondaPackage numpy -Environment myenv
        Removes numpy from the specified environment.
``

## Aliases

This function has the following aliases:

- `conda-remove` - Removes packages using conda.
- `conda-uninstall` - Removes packages using conda.


## Source

Defined in: ..\profile.d\conda.ps1
