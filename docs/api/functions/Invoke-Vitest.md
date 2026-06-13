# Invoke-Vitest

## Synopsis

Executes Vitest test runner.

## Description

Wrapper for vitest command. Uses globally installed vitest if available, otherwise falls back to npx.

## Signature

```powershell
Invoke-Vitest
```

## Parameters

### -Arguments

Arguments to pass to vitest.


## Examples

### Example 1

```powershell
Invoke-Vitest --version
```

### Example 2

```powershell
Invoke-Vitest run
```

## Aliases

This function has the following aliases:

- `vitest` - Executes Vitest test runner.


## Source

Defined in: ../profile.d/dev-tools-modules/build/testing-frameworks.ps1
