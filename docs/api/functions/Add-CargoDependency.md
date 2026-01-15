# Add-CargoDependency

## Synopsis

Adds dependencies to Cargo project.

## Description

Adds packages to Cargo.toml. Supports --dev flag for dev dependencies.

## Signature

```powershell
Add-CargoDependency
```

## Parameters

### -Packages

Package names to add.

### -Dev

Add as dev dependency (--dev).

### -Build

Add as build dependency (--build).

### -Version

Specific version to add (--version).


## Examples

### Example 1

`powershell
Add-CargoDependency serde
    Adds serde as a production dependency.
``

### Example 2

`powershell
Add-CargoDependency tokio-test -Dev
    Adds tokio-test as a dev dependency.
``

## Source

Defined in: ..\profile.d\rustup.ps1
