# Invoke-DenoRun

## Synopsis

Runs Deno scripts.

## Description

Wrapper for deno run command.

## Signature

```powershell
Invoke-DenoRun
```

## Parameters

### -Arguments

Arguments to pass to deno run.


## Examples

### Example 1

`powershell
Invoke-DenoRun app.ts
``

### Example 2

`powershell
Invoke-DenoRun --allow-net server.ts
``

## Aliases

This function has the following aliases:

- `deno-run` - Runs Deno scripts.


## Source

Defined in: ..\profile.d\deno.ps1
