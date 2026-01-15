# Add-JuliaPackage

## Synopsis

Adds Julia packages.

## Description

Adds packages to the current Julia environment. This is equivalent to running 'julia -e "using Pkg; Pkg.add([\"package\"])"'.

## Signature

```powershell
Add-JuliaPackage
```

## Parameters

### -Packages

Package names to add.


## Examples

### Example 1

`powershell
Add-JuliaPackage JSON
        Adds JSON package.
``

## Aliases

This function has the following aliases:

- `julia-add` - Adds Julia packages.


## Source

Defined in: ..\profile.d\julia.ps1
