# Remove-RyePackage

## Synopsis

Removes packages using Rye.

## Description

Removes packages from pyproject.toml. Supports --dev flag.

## Signature

```powershell
Remove-RyePackage
```

## Parameters

### -Packages

Package names to remove.

### -Dev

Remove from dev dependencies (--dev).


## Examples

### Example 1

`powershell
Remove-RyePackage requests
        Removes requests from production dependencies.
``

### Example 2

`powershell
Remove-RyePackage pytest -Dev
        Removes pytest from dev dependencies.
``

## Aliases

This function has the following aliases:

- `ryeremove` - Removes packages using Rye.
- `ryeuninstall` - Removes packages using Rye.


## Source

Defined in: ..\profile.d\rye.ps1
