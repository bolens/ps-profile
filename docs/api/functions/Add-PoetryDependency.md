# Add-PoetryDependency

## Synopsis

Adds dependencies to Poetry project.

## Description

Adds packages as dependencies to pyproject.toml. Supports --group dev, --group test, --group docs flags.

## Signature

```powershell
Add-PoetryDependency
```

## Parameters

### -Packages

Package names to add.

### -Dev

Add as dev dependency (--group dev).

### -Test

Add as test dependency (--group test).

### -Docs

Add as docs dependency (--group docs).

### -Optional

Add as optional dependency (--optional).


## Examples

### Example 1

`powershell
Add-PoetryDependency requests
        Adds requests as a production dependency.
``

### Example 2

`powershell
Add-PoetryDependency pytest -Dev
        Adds pytest as a dev dependency.
``

### Example 3

`powershell
Add-PoetryDependency sphinx -Docs
        Adds sphinx as a docs dependency.
``

## Aliases

This function has the following aliases:

- `poetry-add` - Adds dependencies to Poetry project.


## Source

Defined in: ..\profile.d\poetry.ps1
