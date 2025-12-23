# Invoke-AzureDeveloper

## Synopsis

Executes Azure Developer CLI commands.

## Description

Wrapper function for Azure Developer CLI (azd) that checks for command availability before execution.

## Signature

```powershell
Invoke-AzureDeveloper
```

## Parameters

### -Arguments

Arguments to pass to azd.


## Examples

### Example 1

`powershell
Invoke-AzureDeveloper --version
``

### Example 2

`powershell
Invoke-AzureDeveloper init
``

## Aliases

This function has the following aliases:

- `azd` - Executes Azure Developer CLI commands.


## Source

Defined in: ..\profile.d\50-azure.ps1
