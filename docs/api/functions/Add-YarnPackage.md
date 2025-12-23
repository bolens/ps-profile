# Add-YarnPackage

## Synopsis

Adds packages to project dependencies.

## Description

Wrapper for yarn add command.

## Signature

```powershell
Add-YarnPackage
```

## Parameters

### -Arguments

Arguments to pass to yarn add.


## Examples

### Example 1

`powershell
Add-YarnPackage express
``

### Example 2

`powershell
Add-YarnPackage -D typescript
``

## Aliases

This function has the following aliases:

- `yarn-add` - Installs project dependencies.


## Source

Defined in: ..\profile.d\41-yarn.ps1
