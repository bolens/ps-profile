# Invoke-Mocha

## Synopsis

Executes Mocha test runner.

## Description

Wrapper for mocha command. Uses globally installed mocha if available, otherwise falls back to npx.

## Signature

```powershell
Invoke-Mocha
```

## Parameters

### -Arguments

Arguments to pass to mocha.


## Examples

### Example 1

```powershell
Invoke-Mocha --version
```

### Example 2

```powershell
Invoke-Mocha test
```

## Aliases

This function has the following aliases:

- `mocha` - Executes Mocha test runner.


## Source

Defined in: ../profile.d/dev-tools-modules/build/testing-frameworks.ps1
