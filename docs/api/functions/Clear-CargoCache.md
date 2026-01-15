# Clear-CargoCache

## Synopsis

Cleans up Cargo cache and build artifacts.

## Description

Removes cached crates and build artifacts from Cargo's cache directory. This helps free up disk space by removing downloaded crates and compiled artifacts. Uses cargo-cache if available, otherwise falls back to manual cleanup.

## Signature

```powershell
Clear-CargoCache
```

## Parameters

### -Autoclean

Use cargo cache --autoclean to automatically clean unused cache entries.

### -All

Remove all cache entries (use with caution).


## Outputs

System.String. Output from cargo cache cleanup execution.


## Examples

### Example 1

`powershell
Clear-CargoCache
        Cleans up unused cache entries automatically.
``

### Example 2

`powershell
Clear-CargoCache -Autoclean
        Uses cargo cache --autoclean for automatic cleanup.
``

### Example 3

`powershell
Clear-CargoCache -All
        Removes all cache entries (aggressive cleanup).
``

## Aliases

This function has the following aliases:

- `cargo-clean` - Cleans up Cargo cache and build artifacts.
- `cargo-cleanup` - Cleans up Cargo cache and build artifacts.


## Source

Defined in: ..\profile.d\lang-rust.ps1
