# Update-RyePackages

## Synopsis

Updates packages using Rye.

## Description

Updates specified packages or all packages if no arguments provided.

## Signature

```powershell
Update-RyePackages
```

## Parameters

### -Packages

Package names to update. Optional - updates all if omitted.


## Examples

### Example 1

`powershell
Update-RyePackages
        Updates all packages.
``

### Example 2

`powershell
Update-RyePackages requests
        Updates requests package.
``

## Aliases

This function has the following aliases:

- `ryeupdate` - Updates packages using Rye.


## Source

Defined in: ..\profile.d\rye.ps1
