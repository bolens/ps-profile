# Remove-CargoPackage

## Synopsis

Removes globally installed Cargo packages.

## Description

Removes packages installed with cargo install.

## Signature

```powershell
Remove-CargoPackage
```

## Parameters

### -Packages

Package names to remove.


## Examples

### Example 1

`powershell
Remove-CargoPackage cargo-watch
    Removes cargo-watch from global installation.
``

## Source

Defined in: ..\profile.d\rustup.ps1
