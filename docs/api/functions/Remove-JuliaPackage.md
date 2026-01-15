# Remove-JuliaPackage

## Synopsis

Removes Julia packages.

## Description

Removes packages from the current Julia environment. This is equivalent to running 'julia -e "using Pkg; Pkg.rm([\"package\"])"'.

## Signature

```powershell
Remove-JuliaPackage
```

## Parameters

### -Packages

Package names to remove.


## Examples

### Example 1

`powershell
Remove-JuliaPackage JSON
        Removes JSON package.
``

## Aliases

This function has the following aliases:

- `julia-remove` - Removes Julia packages.


## Source

Defined in: ..\profile.d\julia.ps1
