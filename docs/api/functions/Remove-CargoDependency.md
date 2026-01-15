# Remove-CargoDependency

## Synopsis

Removes dependencies from Cargo project.

## Description

Removes packages from Cargo.toml. Supports --dev flag.

## Signature

```powershell
Remove-CargoDependency
```

## Parameters

### -Packages

Package names to remove.

### -Dev

Remove from dev dependencies (--dev).

### -Build

Remove from build dependencies (--build).


## Examples

### Example 1

`powershell
Remove-CargoDependency serde
    Removes serde from production dependencies.
``

### Example 2

`powershell
Remove-CargoDependency tokio-test -Dev
    Removes tokio-test from dev dependencies.
``

## Source

Defined in: ..\profile.d\rustup.ps1
