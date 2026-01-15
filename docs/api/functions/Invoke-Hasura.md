# Invoke-Hasura

## Synopsis

Executes Hasura CLI commands.

## Description

Wrapper function for Hasura CLI that checks for command availability before execution.

## Signature

```powershell
Invoke-Hasura
```

## Parameters

### -Arguments

Arguments to pass to hasura.


## Examples

### Example 1

`powershell
Invoke-Hasura version
``

### Example 2

`powershell
Invoke-Hasura migrate apply
``

## Aliases

This function has the following aliases:

- `hasura` - Executes Hasura CLI commands.


## Source

Defined in: ..\profile.d\database.ps1
