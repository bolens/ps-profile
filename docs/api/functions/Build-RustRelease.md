# Build-RustRelease

## Synopsis

Builds a Rust project in release mode with optimizations.

## Description

Wrapper function for building Rust projects in release mode. This runs 'cargo build --release' which enables optimizations and produces smaller, faster binaries suitable for production use.

## Signature

```powershell
Build-RustRelease
```

## Parameters

### -Arguments

Additional arguments to pass to cargo build. Can be used multiple times or as an array.


## Outputs

System.String. Output from cargo build execution.


## Examples

### Example 1

`powershell
Build-RustRelease
        Builds the current project in release mode.
``

### Example 2

`powershell
Build-RustRelease --bin myapp
        Builds a specific binary in release mode.
``

## Aliases

This function has the following aliases:

- `cargo-build-release` - Builds a Rust project in release mode with optimizations.


## Source

Defined in: ..\profile.d\lang-rust.ps1
