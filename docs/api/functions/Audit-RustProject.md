# Audit-RustProject

## Synopsis

Audits Rust project dependencies for security vulnerabilities.

## Description

Wrapper function for cargo-audit, which checks Rust dependencies against the RustSec advisory database for known security vulnerabilities.

## Signature

```powershell
Audit-RustProject
```

## Parameters

### -Arguments

Additional arguments to pass to cargo-audit. Can be used multiple times or as an array.


## Outputs

System.String. Output from cargo-audit execution.


## Examples

### Example 1

`powershell
Audit-RustProject
        Audits the current Rust project for security vulnerabilities.
``

### Example 2

`powershell
Audit-RustProject --deny warnings
        Audits and treats warnings as errors.
``

## Aliases

This function has the following aliases:

- `cargo-audit` - Audits Rust project dependencies for security vulnerabilities.


## Source

Defined in: ..\profile.d\lang-rust.ps1
