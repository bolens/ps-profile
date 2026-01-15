# Install-VcpkgPackage

## Synopsis

Installs C++ libraries using vcpkg.

## Description

Installs packages from vcpkg registry. Supports --triplet and --version flags.

## Signature

```powershell
Install-VcpkgPackage
```

## Parameters

### -Packages

Package names to install.

### -Triplet

Target triplet (e.g., x64-windows, x64-linux).

### -Version

Specific version to install.


## Examples

### Example 1

`powershell
Install-VcpkgPackage boost
        Installs boost library.
``

### Example 2

`powershell
Install-VcpkgPackage boost -Triplet x64-windows
        Installs for specific platform.
``

## Aliases

This function has the following aliases:

- `vcpkgadd` - Installs C++ libraries using vcpkg.
- `vcpkginstall` - Installs C++ libraries using vcpkg.


## Source

Defined in: ..\profile.d\vcpkg.ps1
