# Invoke-Esbuild

## Synopsis

Executes esbuild commands.

## Description

Wrapper for esbuild command. Uses globally installed esbuild if available, otherwise falls back to npx.

## Signature

```powershell
Invoke-Esbuild
```

## Parameters

### -Arguments

Arguments to pass to esbuild.


## Examples

### Example 1

`powershell
Invoke-Esbuild --version
``

### Example 2

`powershell
Invoke-Esbuild app.js --bundle --outfile=app.bundle.js
``

## Aliases

This function has the following aliases:

- `esbuild` - Executes esbuild commands.


## Source

Defined in: ../profile.d/dev-tools-modules/build/build-tools.ps1
