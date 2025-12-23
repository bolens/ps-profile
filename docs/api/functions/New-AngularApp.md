# New-AngularApp

## Synopsis

Creates a new Angular application.

## Description

Wrapper for Angular CLI new command. Prefers npx @angular/cli, falls back to globally installed ng.

## Signature

```powershell
New-AngularApp
```

## Parameters

### -Arguments

Arguments to pass to ng new.


## Examples

### Example 1

`powershell
New-AngularApp my-app
``

### Example 2

`powershell
New-AngularApp my-app --routing --style scss
``

## Aliases

This function has the following aliases:

- `ng-new` - Creates a new Angular application.


## Source

Defined in: ..\profile.d\47-angular.ps1
