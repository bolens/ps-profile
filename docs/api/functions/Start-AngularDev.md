# Start-AngularDev

## Synopsis

Starts Angular development server.

## Description

Wrapper for Angular CLI serve command. Prefers npx @angular/cli, falls back to globally installed ng.

## Signature

```powershell
Start-AngularDev
```

## Parameters

### -Arguments

Arguments to pass to ng serve.


## Examples

### Example 1

`powershell
Start-AngularDev
``

### Example 2

`powershell
Start-AngularDev --port 4200
``

## Aliases

This function has the following aliases:

- `ng-serve` - Starts Angular development server.


## Source

Defined in: ..\profile.d\47-angular.ps1
