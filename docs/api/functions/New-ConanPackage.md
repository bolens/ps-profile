# New-ConanPackage

## Synopsis

Creates a Conan package.

## Description

Creates and exports a package from a recipe.

## Signature

```powershell
New-ConanPackage
```

## Parameters

### -Path

Path to conanfile.py.

### -Profile

Profile name to use.


## Examples

### Example 1

`powershell
New-ConanPackage ./conanfile.py
        Creates package from recipe.
``

## Aliases

This function has the following aliases:

- `conancreate` - Creates a Conan package.


## Source

Defined in: ..\profile.d\conan.ps1
