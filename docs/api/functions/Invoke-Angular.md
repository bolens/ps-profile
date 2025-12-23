# Invoke-Angular

## Synopsis

Executes Angular CLI commands.

## Description

Wrapper function for Angular CLI that checks for command availability before execution. Prefers npx @angular/cli, falls back to globally installed ng.

## Signature

```powershell
Invoke-Angular
```

## Parameters

### -Arguments

Arguments to pass to Angular CLI.


## Examples

### Example 1

`powershell
Invoke-Angular --version
``

### Example 2

`powershell
Invoke-Angular generate component my-component
``

## Aliases

This function has the following aliases:

- `ng` - Executes Angular CLI commands.


## Source

Defined in: ..\profile.d\47-angular.ps1
