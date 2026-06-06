# Invoke-Turbo

## Synopsis

Executes Turbo commands.

## Description

Wrapper for turbo command. Uses globally installed turbo if available, otherwise falls back to npx.

## Signature

```powershell
Invoke-Turbo
```

## Parameters

### -Arguments

Arguments to pass to turbo.


## Examples

### Example 1

`powershell
Invoke-Turbo --version
``

### Example 2

`powershell
Invoke-Turbo build
``

## Aliases

This function has the following aliases:

- `turbo` - Executes Turbo commands.


## Source

Defined in: ../profile.d/dev-tools-modules/build/build-tools.ps1
