# Update-PdmPackages

## Synopsis

Updates packages using PDM.

## Description

Updates specified packages or all packages if no arguments provided.

## Signature

```powershell
Update-PdmPackages
```

## Parameters

### -Packages

Package names to update (optional, updates all if omitted).


## Examples

### Example 1

`powershell
Update-PdmPackages
        Updates all packages.
``

### Example 2

`powershell
Update-PdmPackages requests
        Updates requests package.
``

## Aliases

This function has the following aliases:

- `pdmupdate` - Updates packages using PDM.


## Source

Defined in: ..\profile.d\pdm.ps1
