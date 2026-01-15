# Add-RyePackage

## Synopsis

Adds packages using Rye.

## Description

Adds packages to pyproject.toml. Supports --dev, --optional flags.

## Signature

```powershell
Add-RyePackage
```

## Parameters

### -Packages

Package names to add.

### -Dev

Add as dev dependency (--dev).

### -Optional

Add as optional dependency (--optional).


## Examples

### Example 1

`powershell
Add-RyePackage requests
        Adds requests as production dependency.
``

### Example 2

`powershell
Add-RyePackage pytest -Dev
        Adds pytest as dev dependency.
``

## Aliases

This function has the following aliases:

- `ryeadd` - Adds packages using Rye.
- `ryeinstall` - Adds packages using Rye.


## Source

Defined in: ..\profile.d\rye.ps1
