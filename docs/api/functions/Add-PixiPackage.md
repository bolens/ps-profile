# Add-PixiPackage

## Synopsis

Adds packages to pixi project.

## Description

Adds packages to the pixi environment. Supports --channel flag.

## Signature

```powershell
Add-PixiPackage
```

## Parameters

### -Packages

Package names to add.

### -Channel

Channel to install from (--channel).


## Examples

### Example 1

`powershell
Add-PixiPackage numpy
        Adds numpy to the project.
``

### Example 2

`powershell
Add-PixiPackage numpy -Channel conda-forge
        Adds numpy from conda-forge channel.
``

## Aliases

This function has the following aliases:

- `pixi-add` - Adds packages to pixi project.


## Source

Defined in: ..\profile.d\pixi.ps1
