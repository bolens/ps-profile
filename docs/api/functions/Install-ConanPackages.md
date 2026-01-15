# Install-ConanPackages

## Synopsis

Installs C++ packages using Conan.

## Description

Installs packages from conanfile.txt or conanfile.py. Supports --build and --profile flags.

## Signature

```powershell
Install-ConanPackages
```

## Parameters

### -Path

Path to conanfile (optional, uses current directory if omitted).

### -Build

Build policy (missing, outdated, all, never).

### -Profile

Profile name to use.


## Examples

### Example 1

`powershell
Install-ConanPackages
        Installs dependencies from current directory.
``

### Example 2

`powershell
Install-ConanPackages -Build missing
        Installs and builds missing packages.
``

## Aliases

This function has the following aliases:

- `conaninstall` - Installs C++ packages using Conan.


## Source

Defined in: ..\profile.d\conan.ps1
