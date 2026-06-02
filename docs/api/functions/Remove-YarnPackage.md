# Remove-YarnPackage

## Synopsis

Removes packages from project dependencies.

## Description

Wrapper for yarn remove command.

## Signature

```powershell
Remove-YarnPackage
```

## Parameters

### -Arguments

Arguments to pass to yarn remove.


## Examples

### Example 1

`powershell
Remove-YarnPackage express
``

### Example 2

`powershell
Remove-YarnPackage typescript -D
``

## Aliases

This function has the following aliases:

- `yarn-remove` - Removes packages from project dependencies.


## Source

Defined in: ../profile.d/yarn.ps1
