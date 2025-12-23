# Invoke-Firebase

## Synopsis

Executes Firebase CLI commands.

## Description

Wrapper function for Firebase CLI that checks for command availability before execution.

## Signature

```powershell
Invoke-Firebase
```

## Parameters

### -Arguments

Arguments to pass to firebase.


## Examples

### Example 1

`powershell
Invoke-Firebase --version
``

### Example 2

`powershell
Invoke-Firebase login
``

## Aliases

This function has the following aliases:

- `fb` - Executes Firebase CLI commands.


## Source

Defined in: ..\profile.d\38-firebase.ps1
