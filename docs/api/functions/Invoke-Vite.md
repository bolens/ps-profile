# Invoke-Vite

## Synopsis

Executes Vite commands.

## Description

Wrapper function for Vite CLI that checks for command availability before execution.

## Signature

```powershell
Invoke-Vite
```

## Parameters

### -Arguments

Arguments to pass to vite.


## Examples

### Example 1

`powershell
Invoke-Vite --version
``

### Example 2

`powershell
Invoke-Vite build
``

## Aliases

This function has the following aliases:

- `vite` - Executes Vite commands.


## Source

Defined in: ..\profile.d\46-vite.ps1
