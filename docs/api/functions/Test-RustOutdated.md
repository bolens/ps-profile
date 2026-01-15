# Test-RustOutdated

## Synopsis

Checks for outdated Rust dependencies.

## Description

Wrapper function for cargo-outdated, which checks Rust project dependencies for available updates and displays version information.

## Signature

```powershell
Test-RustOutdated
```

## Parameters

### -Arguments

Additional arguments to pass to cargo-outdated. Can be used multiple times or as an array.


## Outputs

System.String. Output from cargo-outdated execution.


## Examples

### Example 1

`powershell
Test-RustOutdated
        Checks for outdated dependencies in the current project.
``

### Example 2

`powershell
Test-RustOutdated --aggressive
        Checks for more aggressive updates including minor version bumps.
``

## Aliases

This function has the following aliases:

- `cargo-outdated` - Checks for outdated Rust dependencies.


## Source

Defined in: ..\profile.d\lang-rust.ps1
