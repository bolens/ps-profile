# Invoke-Playwright

## Synopsis

Executes Playwright commands.

## Description

Wrapper for playwright command. Uses globally installed playwright if available, otherwise falls back to npx.

## Signature

```powershell
Invoke-Playwright
```

## Parameters

### -Arguments

Arguments to pass to playwright.


## Examples

### Example 1

```powershell
Invoke-Playwright --version
```

### Example 2

```powershell
Invoke-Playwright test
```

## Aliases

This function has the following aliases:

- `playwright` - Executes Playwright commands.


## Source

Defined in: ../profile.d/dev-tools-modules/build/testing-frameworks.ps1
