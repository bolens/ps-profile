# Invoke-Azure

## Synopsis

Executes Azure CLI commands.

## Description

Wrapper function for Azure CLI that checks for command availability before execution.

## Signature

```powershell
Invoke-Azure
```

## Parameters

### -Arguments

Arguments to pass to az.


## Examples

### Example 1

`powershell
Invoke-Azure --version
``

### Example 2

`powershell
Invoke-Azure account list
``

## Aliases

This function has the following aliases:

- `az` - Executes Azure CLI commands.


## Source

Defined in: ..\profile.d\azure.ps1
