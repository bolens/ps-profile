# Get-AsdfTools

## Synopsis

Lists installed asdf tools.

## Description

Shows all installed tool versions.

## Signature

```powershell
Get-AsdfTools
```

## Parameters

### -Tool

Tool name (optional, shows all if omitted).


## Examples

### Example 1

`powershell
Get-AsdfTools
        Lists all installed tools.
``

### Example 2

`powershell
Get-AsdfTools nodejs
        Lists installed Node.js versions.
``

## Aliases

This function has the following aliases:

- `asdflist` - Lists installed asdf tools.


## Source

Defined in: ..\profile.d\asdf.ps1
