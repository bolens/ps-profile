# Remove-PoetryDependency

## Synopsis

Removes dependencies from Poetry project.

## Description

Removes packages from pyproject.toml. Supports --group flags.

## Signature

```powershell
Remove-PoetryDependency
```

## Parameters

### -Packages

Package names to remove.

### -Dev

Remove from dev dependencies (--group dev).

### -Test

Remove from test dependencies (--group test).

### -Docs

Remove from docs dependencies (--group docs).


## Examples

### Example 1

`powershell
Remove-PoetryDependency requests
        Removes requests from production dependencies.
``

### Example 2

`powershell
Remove-PoetryDependency pytest -Dev
        Removes pytest from dev dependencies.
``

## Aliases

This function has the following aliases:

- `poetry-remove` - Removes dependencies from Poetry project.


## Source

Defined in: ..\profile.d\poetry.ps1
