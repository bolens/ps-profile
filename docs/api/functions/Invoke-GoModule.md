# Invoke-GoModule

## Synopsis

Manages Go modules.

## Description

Wrapper for go mod command.

## Signature

```powershell
Invoke-GoModule
```

## Parameters

### -Arguments

Arguments to pass to go mod.


## Examples

### Example 1

`powershell
Invoke-GoModule init
``

### Example 2

`powershell
Invoke-GoModule tidy
``

## Aliases

This function has the following aliases:

- `go-mod` - Manages Go modules.


## Source

Defined in: ..\profile.d\53-go.ps1
