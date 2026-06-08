# Invoke-Cypress

## Synopsis

Executes Cypress commands.

## Description

Wrapper for cypress command. Uses globally installed cypress if available, otherwise falls back to npx.

## Signature

```powershell
Invoke-Cypress
```

## Parameters

### -Arguments

Arguments to pass to cypress.


## Examples

### Example 1

```powershell
Invoke-Cypress --version
```

### Example 2

```powershell
Invoke-Cypress open
```

## Aliases

This function has the following aliases:

- `cypress` - Executes Cypress commands.


## Source

Defined in: ../profile.d/dev-tools-modules/build/testing-frameworks.ps1
