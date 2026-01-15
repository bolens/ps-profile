# Add-MixDependency

## Synopsis

Adds Mix dependencies.

## Description

Note: Mix dependencies are added by editing mix.exs. This function provides guidance and then runs mix deps.get.

## Signature

```powershell
Add-MixDependency
```

## Parameters

### -Package

Package name to add (e.g., 'phoenix').

### -Version

Version requirement (e.g., '~> 1.7').


## Examples

### Example 1

`powershell
Add-MixDependency -Package phoenix -Version '~> 1.7'
        Provides instructions for adding Phoenix dependency.
``

## Aliases

This function has the following aliases:

- `mix-add` - Adds Mix dependencies.


## Source

Defined in: ..\profile.d\mix.ps1
