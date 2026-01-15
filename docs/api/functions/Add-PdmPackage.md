# Add-PdmPackage

## Synopsis

Adds packages using PDM.

## Description

Adds packages to pyproject.toml. Supports --dev, --group flags.

## Signature

```powershell
Add-PdmPackage
```

## Parameters

### -Packages

Package names to add.

### -Dev

Add as dev dependency (--dev).

### -Group

Add to specific group (--group).


## Examples

### Example 1

`powershell
Add-PdmPackage requests
        Adds requests as production dependency.
``

### Example 2

`powershell
Add-PdmPackage pytest -Dev
        Adds pytest as dev dependency.
``

## Aliases

This function has the following aliases:

- `pdmadd` - Adds packages using PDM.
- `pdminstall` - Adds packages using PDM.


## Source

Defined in: ..\profile.d\pdm.ps1
