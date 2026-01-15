# Update-CargoPackages

## Synopsis

Updates all installed cargo packages to their latest versions.

## Description

Updates all globally installed cargo packages using cargo-install-update. This is equivalent to running 'cargo install-update --all'. Requires the cargo-install-update crate to be installed.

## Signature

```powershell
Update-CargoPackages
```

## Parameters

No parameters.

## Examples

### Example 1

`powershell
Update-CargoPackages
    Updates all globally installed cargo packages.
``

## Aliases

This function has the following aliases:

- `cargo-update` - Updates all installed cargo packages to their latest versions.


## Source

Defined in: ..\profile.d\rustup.ps1
