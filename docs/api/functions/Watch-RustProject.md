# Watch-RustProject

## Synopsis

Watches files and runs cargo commands on changes.

## Description

Wrapper function for cargo-watch, a file watcher that automatically runs cargo commands when files change. Useful for continuous testing and building.

## Signature

```powershell
Watch-RustProject
```

## Parameters

### -Command

Cargo command to run (e.g., 'test', 'build', 'run'). Defaults to 'check' if not specified.

### -Arguments

Additional arguments to pass to cargo-watch. Can be used multiple times or as an array.


## Outputs

System.String. Output from cargo-watch execution.


## Examples

### Example 1

`powershell
Watch-RustProject
        Watches for changes and runs 'cargo check'.
``

### Example 2

`powershell
Watch-RustProject -Command test
        Watches for changes and runs 'cargo test'.
``

### Example 3

`powershell
Watch-RustProject -Command run -- --release
        Watches for changes and runs 'cargo run --release'.
``

## Aliases

This function has the following aliases:

- `cargo-watch` - Watches files and runs cargo commands on changes.


## Source

Defined in: ..\profile.d\lang-rust.ps1
