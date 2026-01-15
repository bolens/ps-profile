# Invoke-Helm

## Synopsis

Executes Helm commands.

## Description

Wrapper function for Helm CLI that checks for command availability before execution.

## Signature

```powershell
Invoke-Helm
```

## Parameters

### -Arguments

Arguments to pass to helm.


## Examples

### Example 1

`powershell
Invoke-Helm --version
``

### Example 2

`powershell
Invoke-Helm list
``

## Aliases

This function has the following aliases:

- `helm` - Executes Helm commands.


## Source

Defined in: ..\profile.d\helm.ps1
