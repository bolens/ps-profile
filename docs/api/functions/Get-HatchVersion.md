# Get-HatchVersion

## Synopsis

Gets or sets project version.

## Description

Shows or updates the project version.

## Signature

```powershell
Get-HatchVersion
```

## Parameters

### -Version

Version to set (optional, shows current if omitted).


## Examples

### Example 1

`powershell
Get-HatchVersion
        Shows current version.
``

### Example 2

`powershell
Set-HatchVersion -Version 1.2.3
        Sets version to 1.2.3.
``

## Aliases

This function has the following aliases:

- `hatchversion` - Gets or sets project version.


## Source

Defined in: ..\profile.d\hatch.ps1
