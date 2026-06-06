# Invoke-Serve

## Synopsis

Serves static files.

## Description

Wrapper for serve command. Uses globally installed serve if available, otherwise falls back to npx.

## Signature

```powershell
Invoke-Serve
```

## Parameters

### -Arguments

Arguments to pass to serve.


## Examples

### Example 1

`powershell
Invoke-Serve
``

### Example 2

`powershell
Invoke-Serve -p 3000
``

## Aliases

This function has the following aliases:

- `serve` - Serves static files.


## Source

Defined in: ../profile.d/dev-tools-modules/build/build-tools.ps1
