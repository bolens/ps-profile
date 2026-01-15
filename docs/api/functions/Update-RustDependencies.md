# Update-RustDependencies

## Synopsis

Updates Rust project dependencies to their latest compatible versions.

## Description

Updates Cargo.toml dependencies to their latest versions within the specified version constraints. This is a convenience wrapper around cargo update.

## Signature

```powershell
Update-RustDependencies
```

## Parameters

### -Arguments

Additional arguments to pass to cargo update. Can be used multiple times or as an array.


## Outputs

System.String. Output from cargo update execution.


## Examples

### Example 1

`powershell
Update-RustDependencies
        Updates all dependencies in the current project.
``

### Example 2

`powershell
Update-RustDependencies --package serde
        Updates only the serde package.
``

## Aliases

This function has the following aliases:

- `cargo-update-deps` - Updates Rust project dependencies to their latest compatible versions.


## Source

Defined in: ..\profile.d\lang-rust.ps1
