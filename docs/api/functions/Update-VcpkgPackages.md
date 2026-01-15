# Update-VcpkgPackages

## Synopsis

Upgrades vcpkg packages.

## Description

Upgrades specified packages or all packages if no arguments provided.

## Signature

```powershell
Update-VcpkgPackages
```

## Parameters

### -Packages

Package names to upgrade (optional, upgrades all if omitted).

### -NoDryRun

Actually perform upgrades (default is dry-run).


## Examples

### Example 1

`powershell
Update-VcpkgPackages
        Shows what would be upgraded (dry-run).
``

### Example 2

`powershell
Update-VcpkgPackages boost -NoDryRun
        Upgrades boost package.
``

## Aliases

This function has the following aliases:

- `vcpkgupdate` - Upgrades vcpkg packages.
- `vcpkgupgrade` - Upgrades vcpkg packages.


## Source

Defined in: ..\profile.d\vcpkg.ps1
