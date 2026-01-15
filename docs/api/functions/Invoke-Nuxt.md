# Invoke-Nuxt

## Synopsis

Executes Nuxt CLI (nuxi) commands.

## Description

Wrapper function for Nuxt CLI that checks for command availability before execution.

## Signature

```powershell
Invoke-Nuxt
```

## Parameters

### -Arguments

Arguments to pass to nuxi.


## Examples

### Example 1

`powershell
Invoke-Nuxt --version
``

### Example 2

`powershell
Invoke-Nuxt init my-app
``

## Aliases

This function has the following aliases:

- `nuxi` - Executes Nuxt CLI (nuxi) commands.


## Source

Defined in: ..\profile.d\nuxt.ps1
