# Invoke-Bunx

## Synopsis

Executes packages using bunx.

## Description

Wrapper for bunx command that runs packages without installing them globally.

## Signature

```powershell
Invoke-Bunx
```

## Parameters

### -Arguments

Arguments to pass to bunx.


## Examples

### Example 1

`powershell
Invoke-Bunx create next-app
``

### Example 2

`powershell
Invoke-Bunx --version
``

## Aliases

This function has the following aliases:

- `bunx` - Executes packages using bunx.


## Source

Defined in: ..\profile.d\bun.ps1
