# Invoke-Yarn

## Synopsis

Executes Yarn commands.

## Description

Wrapper function for Yarn CLI that checks for command availability before execution.

## Signature

```powershell
Invoke-Yarn
```

## Parameters

### -Arguments

Arguments to pass to yarn.


## Examples

### Example 1

`powershell
Invoke-Yarn --version
``

### Example 2

`powershell
Invoke-Yarn install
``

## Aliases

This function has the following aliases:

- `yarn` - Installs project dependencies.


## Source

Defined in: ..\profile.d\41-yarn.ps1
