# Invoke-Rustup

## Synopsis

Executes Rustup commands.

## Description

Wrapper function for Rustup CLI that checks for command availability before execution.

## Signature

```powershell
Invoke-Rustup
```

## Parameters

### -Arguments

Arguments to pass to rustup.


## Examples

### Example 1

`powershell
Invoke-Rustup --version
``

### Example 2

`powershell
Invoke-Rustup show
``

## Aliases

This function has the following aliases:

- `rustup` - Executes Rustup commands.


## Source

Defined in: ..\profile.d\39-rustup.ps1
