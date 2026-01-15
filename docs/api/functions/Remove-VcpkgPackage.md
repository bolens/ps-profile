# Remove-VcpkgPackage

## Synopsis

Removes C++ libraries using vcpkg.

## Description

Removes installed packages.

## Signature

```powershell
Remove-VcpkgPackage
```

## Parameters

### -Packages

Package names to remove.

### -Triplet

Target triplet.


## Examples

### Example 1

`powershell
Remove-VcpkgPackage boost
        Removes boost library.
``

## Aliases

This function has the following aliases:

- `vcpkgremove` - Removes C++ libraries using vcpkg.
- `vcpkguninstall` - Removes C++ libraries using vcpkg.


## Source

Defined in: ..\profile.d\vcpkg.ps1
