# Invoke-Jest

## Synopsis

Executes Jest test runner.

## Description

Wrapper for jest command. Uses globally installed jest if available, otherwise falls back to npx.

## Signature

```powershell
Invoke-Jest
```

## Parameters

### -Arguments

Arguments to pass to jest.


## Examples

### Example 1

`powershell
Invoke-Jest --version
``

### Example 2

`powershell
Invoke-Jest test
``

## Aliases

This function has the following aliases:

- `jest` - Executes Jest test runner.


## Source

Defined in: ../profile.d/dev-tools-modules/build/testing-frameworks.ps1
