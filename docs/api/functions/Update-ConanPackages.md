# Update-ConanPackages

## Synopsis

Updates Conan packages.

## Description

Updates specified packages or all packages if no arguments provided. Uses 'conan install' with --update flag to update dependencies.

## Signature

```powershell
Update-ConanPackages
```

## Parameters

### -Packages

Package names to update (optional, updates all if omitted).

### -Path

Path to conanfile (optional, uses current directory if omitted).

### -Build

Build policy (missing, outdated, all, never).

### -Profile

Profile name to use.


## Examples

### Example 1

`powershell
Update-ConanPackages
        Updates all packages in current directory.
``

### Example 2

`powershell
Update-ConanPackages -Path ./conanfile.txt
        Updates all packages in specific file.
``

### Example 3

`powershell
Update-ConanPackages -Build outdated
        Updates and rebuilds outdated packages.
``

## Aliases

This function has the following aliases:

- `conanupdate` - Updates Conan packages.


## Source

Defined in: ..\profile.d\conan.ps1
