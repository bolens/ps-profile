# Remove-PdmPackage

## Synopsis

Removes packages using PDM.

## Description

Removes packages from pyproject.toml. Supports --dev, --group flags.

## Signature

```powershell
Remove-PdmPackage
```

## Parameters

### -Packages

Package names to remove.

### -Dev

Remove from dev dependencies (--dev).

### -Group

Remove from specific group (--group).


## Examples

### Example 1

`powershell
Remove-PdmPackage requests
        Removes requests from production dependencies.
``

### Example 2

`powershell
Remove-PdmPackage pytest -Dev
        Removes pytest from dev dependencies.
``

## Aliases

This function has the following aliases:

- `pdmremove` - Removes packages using PDM.
- `pdmuninstall` - Removes packages using PDM.


## Source

Defined in: ..\profile.d\pdm.ps1
