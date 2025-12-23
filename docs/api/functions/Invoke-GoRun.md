# Invoke-GoRun

## Synopsis

Runs Go programs.

## Description

Wrapper for go run command.

## Signature

```powershell
Invoke-GoRun
```

## Parameters

### -Arguments

Arguments to pass to go run.


## Examples

### Example 1

`powershell
Invoke-GoRun main.go
``

### Example 2

`powershell
Invoke-GoRun ./cmd/server
``

## Aliases

This function has the following aliases:

- `go-run` - Runs Go programs.


## Source

Defined in: ..\profile.d\53-go.ps1
