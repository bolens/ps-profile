# Install-RustBinary

## Synopsis

Installs Rust binaries using cargo-binstall.

## Description

Wrapper function for cargo-binstall, a fast binary installer for Rust tools. cargo-binstall downloads pre-built binaries instead of compiling from source, making installation much faster than cargo install.

## Signature

```powershell
Install-RustBinary
```

## Parameters

### -Packages

Package names to install. Can be used multiple times or as an array.

### -Version

Specific version to install (--version).


## Outputs

System.String. Output from cargo-binstall execution.


## Examples

### Example 1

`powershell
Install-RustBinary cargo-watch
        Installs cargo-watch using cargo-binstall.
``

### Example 2

`powershell
Install-RustBinary cargo-audit --version 0.18.0
        Installs a specific version of cargo-audit.
``

## Aliases

This function has the following aliases:

- `cargo-binstall` - Installs Rust binaries using cargo-binstall.


## Source

Defined in: ..\profile.d\lang-rust.ps1
