# Invoke-Deno

## Synopsis

Executes Deno commands.

## Description

Wrapper function for Deno CLI that checks for command availability before execution.

## Signature

```powershell
Invoke-Deno
```

## Parameters

### -Arguments

Arguments to pass to deno.


## Examples

### Example 1

`powershell
Invoke-Deno --version
``

### Example 2

`powershell
Invoke-Deno run app.ts
``

## Aliases

This function has the following aliases:

- `deno` - Executes Deno commands.


## Source

Defined in: ..\profile.d\37-deno.ps1
