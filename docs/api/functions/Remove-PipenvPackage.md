# Remove-PipenvPackage

## Synopsis

Removes packages using Pipenv.

## Description

Removes packages from Pipfile. Supports --dev flag.

## Signature

```powershell
Remove-PipenvPackage
```

## Parameters

### -Packages

Package names to remove.

### -Dev

Remove from dev dependencies (--dev).


## Examples

### Example 1

`powershell
Remove-PipenvPackage requests
        Removes requests from production dependencies.
``

### Example 2

`powershell
Remove-PipenvPackage pytest -Dev
        Removes pytest from dev dependencies.
``

## Aliases

This function has the following aliases:

- `pipenvremove` - Removes packages using Pipenv.
- `pipenvuninstall` - Removes packages using Pipenv.


## Source

Defined in: ..\profile.d\pipenv.ps1
