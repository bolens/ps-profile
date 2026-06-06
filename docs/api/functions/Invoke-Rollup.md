# Invoke-Rollup

## Synopsis

Executes Rollup commands.

## Description

Wrapper for rollup command. Uses globally installed rollup if available, otherwise falls back to npx.

## Signature

```powershell
Invoke-Rollup
```

## Parameters

### -Arguments

Arguments to pass to rollup.


## Examples

### Example 1

`powershell
Invoke-Rollup --version
``

### Example 2

`powershell
Invoke-Rollup -c rollup.config.js
``

## Aliases

This function has the following aliases:

- `rollup` - Executes Rollup commands.


## Source

Defined in: ../profile.d/dev-tools-modules/build/build-tools.ps1
